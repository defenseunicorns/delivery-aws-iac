
//providers.tf
terraform {
  required_providers {
    context = {
      source  = "registry.terraform.io/cloudposse/context"
      version = "~> 0.4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34"
    }
  }
}

//variables.tf
// Standardize on config objects. Use `optional()` to set defaults as needed.
variable "vpc_config" {
  description = "Existing VPC configuration for EKS"
  type = object({
    azs                        = list(string)
    vpc_id                     = string
    public_subnets             = list(string)
    private_subnets            = list(string)
    intra_subnets              = list(string)
    database_subnets           = list(string)
    database_subnet_group_name = string
  })
}
variable "keycloak_config_opts" {
  description = "UDS Keycloak Configuration options to be determined by mission needs."
  type = object({
    key_owners = optional(list(string), [])
  })
  default = {}
}
variable "advanced_overrides" {
  description = "Advanced configuration overrides"
  type        = map(any)
  default     = {}
}

data "context_config" "this" {}
data "context_label" "this" {}
data "context_tags" "this" {}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  context_key = "impact_level"
  //defautls from source aws modules
  keycloak_config_defaults = {
    kms_config = local.aws_kms_defaults
    db_config  = local.aws_rds_defaults
  }
  keycloak_config_contexts = {
    base = [local.base_uds_keycloak_overrides, ]
    il4  = [local.base_uds_keycloak_overrides, ]
    il5  = [local.base_uds_keycloak_overrides, ]
    devx = [local.base_uds_keycloak_overrides, local.devx_overrides]
  }
  context_overrides   = local.keycloak_config_contexts[data.context_config.this.values[local.context_key]]
  uds_keycloak_config = module.config_deepmerge.merged
}

// Override module configuration defaults with impact level and advanced user settings
module "config_deepmerge" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"
  maps = concat(
    [local.keycloak_config_defaults],
    local.context_overrides,
    [var.advanced_overrides],
  )
}

# Create custom policy for KMS
data "aws_iam_policy_document" "kms_access" {
  statement {
    sid = "KMS Key Default"
    principals {
      type = "AWS"
      identifiers = concat(
        ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"],
        local.uds_keycloak_config.kms_config.policy_default_identities
      )
    }

    dynamic "principals" {
      for_each = length(local.uds_keycloak_config.kms_config.policy_default_services) > 0 ? [0] : []
      content {
        type        = "Service"
        identifiers = local.uds_keycloak_config.kms_config.policy_default_services
      }
    }
    actions   = ["kms:*", ]
    resources = ["*"]
  }
  statement {
    sid = "CloudWatchLogsEncryption"
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]

    resources = ["*"]
  }
  statement {
    sid = "Cloudtrail KMS permissions"
    principals {
      type = "Service"
      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]
  }

}

resource "aws_kms_alias" "keycloak_key_alais" {
  name_prefix   = local.uds_keycloak_config.kms_config.key_alias_prefix
  target_key_id = module.kms.key_id
}

# RDS

resource "random_password" "keycloak_db_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "keycloak_db_secret" {
  name                    = local.uds_keycloak_config.db_config.secret_name
  description             = "Keycloak DB authentication token"
  recovery_window_in_days = local.uds_keycloak_config.db_config.secret_recovery_window
  kms_key_id              = module.kms.key_arn
}

module "keycloak_db" {
  source                         = "terraform-aws-modules/rds/aws"
  version                        = "6.9.0"
  subnet_ids                     = var.vpc_config.database_subnets
  db_subnet_group_name           = var.vpc_config.database_subnet_group_name
  vpc_security_group_ids         = [aws_security_group.keycloak_rds_sg.id]
  tags                           = local.uds_keycloak_config.tags
  identifier                     = local.uds_keycloak_config.db_config.identifier
  instance_use_identifier_prefix = local.uds_keycloak_config.db_config.instance_use_identifier_prefix
  allocated_storage              = local.uds_keycloak_config.db_config.allocated_storage
  max_allocated_storage          = local.uds_keycloak_config.db_config.max_allocated_storage
  backup_retention_period        = local.uds_keycloak_config.db_config.backup_retention_period
  backup_window                  = local.uds_keycloak_config.db_config.backup_window
  maintenance_window             = local.uds_keycloak_config.db_config.maintenance_window
  engine                         = local.uds_keycloak_config.db_config.engine
  engine_version                 = local.uds_keycloak_config.db_config.engine_version
  major_engine_version           = local.uds_keycloak_config.db_config.major_engine_version
  family                         = local.uds_keycloak_config.db_config.family
  instance_class                 = local.uds_keycloak_config.db_config.instance_class
  db_name                        = local.uds_keycloak_config.db_config.db_name
  username                       = local.uds_keycloak_config.db_config.username
  port                           = local.uds_keycloak_config.db_config.port
  snapshot_identifier            = local.uds_keycloak_config.db_config.snapshot_identifier
  manage_master_user_password    = local.uds_keycloak_config.db_config.manage_master_user_password
  password                       = random_password.keycloak_db_password.result
  multi_az                       = local.uds_keycloak_config.db_config.multi_az
  copy_tags_to_snapshot          = local.uds_keycloak_config.db_config.copy_tags_to_snapshot
  allow_major_version_upgrade    = local.uds_keycloak_config.db_config.allow_major_version_upgrade
  auto_minor_version_upgrade     = local.uds_keycloak_config.db_config.auto_minor_version_upgrade
  deletion_protection            = local.uds_keycloak_config.db_config.deletion_protection
}

resource "aws_security_group" "keycloak_rds_sg" {
  vpc_id = var.vpc_config.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "keycloak_rds_ingress" {
  security_group_id = aws_security_group.keycloak_rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = local.uds_keycloak_config.db_config.port
}
