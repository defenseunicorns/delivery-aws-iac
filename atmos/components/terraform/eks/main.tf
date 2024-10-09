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
    database_subnets           = optional(list(string))
    database_subnet_group_name = optional(string)
  })
}

// EKS configuration options. We can put in defaults, however defaults
// should not be provided for items that need to be a mission decision.
variable "eks_config_opts" {
  description = "EKS Configuration options to be determined by mission needs."
  type = object({
    default_ami_id                      = string // Default AMI for all node groups
    cluster_version                     = optional(string, "1.30")
    kms_key_admin_usernames             = optional(list(string), [])
    kms_key_admin_arns                  = optional(list(string), [])
    additional_self_managed_node_groups = optional(list(any), [])
  })
}

variable "uds_config_opts" {
  description = "UDS Configuration options to be determined by mission needs."
  type = object({
    keycloak_enabled = optional(bool, true)
    keycloak_ami_id  = optional(string)
  })
  default = {}
}

variable "eks_sensitive_config_opts" {
  sensitive = true
  type = object({
    eks_sensitive_opt1 = optional(string)
    eks_sensitive_opt2 = optional(string)
  })
}

// data.tf?
// Context data sources that spans modules and deploys.
data "context_config" "this" {}
data "context_label" "this" {}
data "context_tags" "this" {}

// AWS
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  # This data source provides information on the IAM source role of an STS assumed role
  # For non-role ARNs, this data source simply passes the ARN through issuer ARN
  # Ref https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2327#issuecomment-1355581682
  # Ref https://github.com/hashicorp/terraform-provider-aws/issues/28381
  arn = data.aws_caller_identity.current.arn
}

// main.tf
locals {
  kms_key_admin_arns = distinct(concat(
    [for admin_user in var.eks_config_opts.kms_key_admin_usernames : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:user/${admin_user}"],
    [data.aws_iam_session_context.current.issuer_arn], var.eks_config_opts.kms_key_admin_arns
  ))

  iam_role_permissions_boundary = lookup(data.context_config.this.values, "permissions_boundary_policy_arn", null) //TODO: add context for tag based IAM permissions boundaries

  il4_eks_overrides = {}
  il5_eks_overrides = merge(local.il4_eks_overrides, {}) // Base is default for IL5

  // Overrides for Developer Experiance (devx). These facilate faster setup/teardown 
  // and more open access for bundle development.
  devx_eks_overrides = {
    subnet_ids                      = var.vpc_config.public_subnets //Public subnets for devX
    control_plane_subnet_ids        = var.vpc_config.private_subnets
    cluster_endpoint_public_access  = true //Public access enabled
    cluster_endpoint_private_access = true //Private access requred
  }

  il4_eks_config  = merge(local.base_eks_config, local.il4_eks_overrides)
  il5_eks_config  = merge(local.base_eks_config, local.il5_eks_overrides)
  devx_eks_config = merge(local.base_eks_config, local.devx_eks_overrides)

  eks_config_contexts = {
    base = local.base_eks_config,
    il4  = local.il4_eks_config,
    il5  = local.il5_eks_config
    devx = local.devx_eks_config
  }
  eks_config = local.eks_config_contexts[data.context_config.this.values["impact_level"]]
}

module "eks" {
  #----------------------------------------------------------------------------------------------------------#
  #   Security groups used in this module created by the upstream modules terraform-aws-eks (https://github.com/terraform-aws-modules/terraform-aws-eks).
  #   Upstream module implemented Security groups based on the best practices doc https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html.
  #   By default the security groups are restrictive. Users needs to enable rules for specific ports required for App requirement or Add-ons
  #----------------------------------------------------------------------------------------------------------#

  source                               = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v20.24.0"
  cluster_name                         = local.eks_config.cluster_name
  cluster_version                      = local.eks_config.cluster_version
  vpc_id                               = local.eks_config.vpc_id
  subnet_ids                           = local.eks_config.subnet_ids
  control_plane_subnet_ids             = local.eks_config.control_plane_subnet_ids
  cluster_ip_family                    = local.eks_config.cluster_ip_family
  iam_role_permissions_boundary        = local.eks_config.iam_role_permissions_boundary
  attach_cluster_encryption_policy     = local.eks_config.attach_cluster_encryption_policy
  cluster_endpoint_public_access       = local.eks_config.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = local.eks_config.cluster_endpoint_public_access_cidrs
  cluster_endpoint_private_access      = local.eks_config.cluster_endpoint_private_access
  //Add dependencies to the node group defaults
  self_managed_node_group_defaults = merge(local.eks_config.self_managed_node_group_defaults,
    {
      subnet_ids = local.eks_config.subnet_ids,
      key_name   = module.default_self_managed_node_group_keypair.key_pair_name
    }
  )
  self_managed_node_groups                     = local.eks_config.self_managed_node_groups
  eks_managed_node_groups                      = local.eks_config.eks_managed_node_groups
  eks_managed_node_group_defaults              = local.eks_config.eks_managed_node_group_defaults
  dataplane_wait_duration                      = local.eks_config.dataplane_wait_duration
  cluster_timeouts                             = local.eks_config.cluster_timeouts
  cluster_addons                               = local.eks_config.cluster_addons
  access_entries                               = local.eks_config.access_entries
  authentication_mode                          = local.eks_config.authentication_mode
  enable_cluster_creator_admin_permissions     = local.eks_config.enable_cluster_creator_admin_permissions
  cluster_security_group_additional_rules      = local.eks_config.cluster_security_group_additional_rules
  cluster_additional_security_group_ids        = local.eks_config.cluster_additional_security_group_ids
  create_cluster_security_group                = local.eks_config.create_cluster_security_group
  cluster_security_group_id                    = local.eks_config.cluster_security_group_id
  cluster_security_group_name                  = local.eks_config.cluster_security_group_name
  cluster_security_group_use_name_prefix       = local.eks_config.cluster_security_group_use_name_prefix
  cluster_security_group_description           = local.eks_config.cluster_security_group_description
  cluster_security_group_tags                  = local.eks_config.cluster_security_group_tags
  create_kms_key                               = local.eks_config.create_kms_key
  kms_key_description                          = local.eks_config.kms_key_description
  kms_key_deletion_window_in_days              = local.eks_config.kms_key_deletion_window_in_days
  enable_kms_key_rotation                      = local.eks_config.enable_kms_key_rotation
  kms_key_enable_default_policy                = local.eks_config.kms_key_enable_default_policy
  kms_key_owners                               = local.eks_config.kms_key_owners
  kms_key_administrators                       = local.eks_config.kms_key_administrators
  kms_key_users                                = local.eks_config.kms_key_users
  kms_key_service_users                        = local.eks_config.kms_key_service_users
  kms_key_source_policy_documents              = local.eks_config.kms_key_source_policy_documents
  kms_key_override_policy_documents            = local.eks_config.kms_key_override_policy_documents
  kms_key_aliases                              = local.eks_config.kms_key_aliases
  cluster_enabled_log_types                    = local.eks_config.cluster_enabled_log_types
  create_cloudwatch_log_group                  = local.eks_config.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days       = local.eks_config.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id              = local.eks_config.cloudwatch_log_group_kms_key_id
  cloudwatch_log_group_class                   = local.eks_config.cloudwatch_log_group_class
  cluster_tags                                 = local.eks_config.cluster_tags
  create_cluster_primary_security_group_tags   = local.eks_config.create_cluster_primary_security_group_tags
  cloudwatch_log_group_tags                    = local.eks_config.cloudwatch_log_group_tags
  tags                                         = local.eks_config.tags
  bootstrap_self_managed_addons                = local.eks_config.bootstrap_self_managed_addons
  cluster_addons_timeouts                      = local.eks_config.cluster_addons_timeouts
  cluster_encryption_config                    = local.eks_config.cluster_encryption_config
  cluster_encryption_policy_description        = local.eks_config.cluster_encryption_policy_description
  cluster_encryption_policy_name               = local.eks_config.cluster_encryption_policy_name
  cluster_encryption_policy_path               = local.eks_config.cluster_encryption_policy_path
  cluster_encryption_policy_tags               = local.eks_config.cluster_encryption_policy_tags
  cluster_encryption_policy_use_name_prefix    = local.eks_config.cluster_encryption_policy_use_name_prefix
  cluster_identity_providers                   = local.eks_config.cluster_identity_providers
  cluster_service_ipv4_cidr                    = local.eks_config.cluster_service_ipv4_cidr
  cluster_service_ipv6_cidr                    = local.eks_config.cluster_service_ipv6_cidr
  cluster_upgrade_policy                       = local.eks_config.cluster_upgrade_policy
  create                                       = local.eks_config.create
  create_cni_ipv6_iam_policy                   = local.eks_config.create_cni_ipv6_iam_policy
  create_iam_role                              = local.eks_config.create_iam_role
  create_node_security_group                   = local.eks_config.create_node_security_group
  custom_oidc_thumbprints                      = local.eks_config.custom_oidc_thumbprints
  enable_efa_support                           = local.eks_config.enable_efa_support
  enable_irsa                                  = local.eks_config.enable_irsa
  fargate_profile_defaults                     = local.eks_config.fargate_profile_defaults
  fargate_profiles                             = local.eks_config.fargate_profiles
  iam_role_additional_policies                 = local.eks_config.iam_role_additional_policies
  iam_role_arn                                 = local.eks_config.iam_role_arn
  iam_role_description                         = local.eks_config.iam_role_description
  iam_role_name                                = local.eks_config.iam_role_name
  iam_role_path                                = local.eks_config.iam_role_path
  iam_role_tags                                = local.eks_config.iam_role_tags
  iam_role_use_name_prefix                     = local.eks_config.iam_role_use_name_prefix
  include_oidc_root_ca_thumbprint              = local.eks_config.include_oidc_root_ca_thumbprint
  node_security_group_additional_rules         = local.eks_config.node_security_group_additional_rules
  node_security_group_description              = local.eks_config.node_security_group_description
  node_security_group_enable_recommended_rules = local.eks_config.node_security_group_enable_recommended_rules
  node_security_group_id                       = local.eks_config.node_security_group_id
  node_security_group_name                     = local.eks_config.node_security_group_name
  node_security_group_tags                     = local.eks_config.node_security_group_tags
  node_security_group_use_name_prefix          = local.eks_config.node_security_group_use_name_prefix
  openid_connect_audiences                     = local.eks_config.openid_connect_audiences
  outpost_config                               = local.eks_config.outpost_config
  prefix_separator                             = local.eks_config.prefix_separator
  putin_khuylo                                 = local.eks_config.putin_khuylo
}

######################################################
# EKS Self Managed Node Group Dependencies
######################################################
module "default_self_managed_node_group_keypair" {
  source             = "git::https://github.com/terraform-aws-modules/terraform-aws-key-pair?ref=v2.0.3"
  key_name_prefix    = "${local.eks_config.cluster_name}-default-ng-"
  create_private_key = true
  tags               = local.eks_config.tags
}

module "default_self_managed_node_group_secret_key_secrets_manager_secret" {
  source                  = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=v1.1.2"
  name                    = module.default_self_managed_node_group_keypair.key_pair_name
  description             = "Secret key for self managed node group keypair"
  recovery_window_in_days = 0 # 0 - no recovery window, delete immediately when deleted
  block_public_policy     = true
  ignore_secret_changes   = true
  secret_string           = module.default_self_managed_node_group_keypair.private_key_openssh
  tags                    = local.eks_config.tags
}

######################################################
#Keycloak Self Managed Node Group Dependencies
######################################################

module "keycloak_self_managed_node_group_keypair" {
  source             = "git::https://github.com/terraform-aws-modules/terraform-aws-key-pair?ref=v2.0.3"
  key_name_prefix    = "${local.eks_config.cluster_name}-keycloak-ng-"
  create_private_key = true
  tags               = local.eks_config.tags
}

module "keycloak_ebs_kms_key" {
  source      = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=v3.1.0"
  description = "Customer managed key to encrypt EKS managed node group volumes"

  # Policy
  key_administrators = [data.aws_iam_session_context.current.issuer_arn]
  key_service_roles_for_autoscaling = [
    # required for the ASG to manage encrypted volumes for nodes
    "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    # required for the cluster / persistentvolume-controller to create encrypted PVCs
    module.eks.cluster_iam_role_arn,
  ]
  # Aliases
  aliases                 = ["eks/keycloak_ng_sso/ebs"]
  aliases_use_name_prefix = true
  tags                    = local.eks_config.tags
}


######################################################
# vpc-cni irsa role
######################################################
module "vpc_cni_ipv4_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.46.0"

  role_name_prefix      = "${local.eks_config.cluster_name}-vpc-cni-"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  # extra policy to attach to the role
  role_policy_arns = {
    vpc_cni_logging = aws_iam_policy.vpc_cni_logging.arn
  }

  role_permissions_boundary_arn = local.eks_config.iam_role_permissions_boundary
  tags                          = local.eks_config.tags
}


resource "aws_iam_policy" "vpc_cni_logging" {
  name        = "${local.eks_config.cluster_name}-vpc-cni-logging"
  description = "Additional test policy"
  tags        = local.eks_config.tags
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "CloudWatchLogging"
          Effect = "Allow"
          Action = [
            "logs:DescribeLogGroups",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "*"
        }
      ]
    }
  )
}


// outputs.tf
// Use Impact Level from context to set the default config for EKS
// This object will be used to configure the official AWS EKS module.
// Outputting for illustration purposes.
output "eks_config" {
  value = local.eks_config_contexts[data.context_config.this.values["impact_level"]]
}
output "eks_opt_config_out" { value = var.eks_config_opts }
output "context" { value = data.context_config.this }
output "eks_vpc_attrs" { value = var.vpc_config }
output "context_tags" { value = data.context_tags.this.tags }
output "example_resource_name_suffix" { value = data.context_label.this.rendered }
