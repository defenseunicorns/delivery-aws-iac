
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


data "context_config" "this" {}
data "context_label" "this" {}
data "context_tags" "this" {}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {

  base_keycloak_kms_key_config = {
    description               = "Keycloak Key"
    deletion_window_in_days   = 7
    enable_key_rotation       = true
    multi_region              = true
    key_owners                = var.keycloak_config_opts.key_owners
    tags                      = data.context_tags.this.tags
    create_external           = false
    key_usage                 = "ENCRYPT_DECRYPT" //"What the key is intended to be used for (ENCRYPT_DECRYPT or SIGN_VERIFY)"
    customer_master_key_spec  = "SYMMETRIC_DEFAULT"
    policy_default_identities = []
    policy_default_services   = []
    key_alias_prefix          = "alias/${data.context_label.this.rendered}"
  }
  base_keycloak_db_config = {
    secret_name                    = "keycloak-db-secret-${data.context_label.this.rendered}"
    secret_recovery_window         = 7
    identifier                     = "keycloak-db"
    instance_class                 = "db.t4g.large"
    db_name                        = "keycloakdb"
    instance_use_identifier_prefix = true
    allocated_storage              = 20
    max_allocated_storage          = 500
    backup_retention_period        = 30
    backup_window                  = "03:00-06:00"
    maintenance_window             = "Mon:00:00-Mon:03:00"
    engine                         = "postgres"
    engine_version                 = "15.6"
    major_engine_version           = "15"
    family                         = "postgres15"
    username                       = "keycloak"
    port                           = "5432"
    manage_master_user_password    = false
    multi_az                       = false
    copy_tags_to_snapshot          = true
    allow_major_version_upgrade    = false
    auto_minor_version_upgrade     = false
    deletion_protection            = false //TODO: Default is true. This needs to be false for development
    snapshot_identifier            = ""    //var.keycloak_db_snapshot
  }


  base_uds_keycloak_config = {
    kms_config = local.base_keycloak_kms_key_config
    db_config  = local.base_keycloak_db_config
    tags       = data.context_tags.this.tags
  }
  uds_keycloak_config = merge(local.base_uds_keycloak_config, {})
}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  description              = local.uds_keycloak_config.kms_config.description
  deletion_window_in_days  = local.uds_keycloak_config.kms_config.deletion_window_in_days
  enable_key_rotation      = local.uds_keycloak_config.kms_config.enable_key_rotation
  policy                   = data.aws_iam_policy_document.kms_access.json
  multi_region             = local.uds_keycloak_config.kms_config.multi_region
  key_owners               = local.uds_keycloak_config.kms_config.key_owners
  tags                     = local.uds_keycloak_config.kms_config.tags
  create_external          = local.uds_keycloak_config.kms_config.create_external
  key_usage                = local.uds_keycloak_config.kms_config.key_usage
  customer_master_key_spec = local.uds_keycloak_config.kms_config.customer_master_key_spec
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

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 5432
}
