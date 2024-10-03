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

// Standardize on config objects. Use `optional()` to set defaults as needed.
variable "vpc_config" {
  description = "Existing VPC configuration for EKS"
  type = object({
    vpc_id                     = string
    subnet_ids                 = list(string)
    azs                        = list(string)
    private_subnet_ids         = list(string)
    intra_subnet_ids           = list(string)
    database_subnets           = optional(list(string))
    database_subnet_group_name = optional(string)
  })
}

// EKS configuration options. We can put in defaults, however defaults
// should not be provided for items that need to be a mission decision.
variable "eks_config_opts" {
  description = "EKS Configuration options to be determined by mission needs."
  type = object({
    cluster_version         = optional(string, "1.30")
    kms_key_admin_usernames = optional(list(string), [])
    kms_key_admin_arns      = optional(list(string), [])
  })
  default = {
    cluster_version = "1.30"
  }
}

variable "eks_sensitive_config_opts" {
  sensitive = true
  type = object({
    eks_sensitive_opt1 = optional(string)
    eks_sensitive_opt2 = optional(string)
  })
}

locals {
  kms_key_admin_arns = distinct(concat(
    [for admin_user in var.eks_config_opts.kms_key_admin_usernames : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:user/${admin_user}"],
    [data.aws_iam_session_context.current.issuer_arn], var.eks_config_opts.kms_key_admin_arns
  ))
  // Context for base shall be IL5
  //Fixed settings for base (IL5)
  base_eks_config = {
    vpc_id                          = var.vpc_config.vpc_id
    subnet_ids                      = var.vpc_config.private_subnet_ids //Private subnets by default for base
    control_plane_subnet_ids        = var.vpc_config.private_subnet_ids
    tags                            = data.context_tags.this.tags
    cluster_name                    = data.context_label.this.rendered
    iam_role_permissions_boundary   = lookup(data.context_config.this.values, "PermissionsBoundary", null) //TODO: add context for tag based IAM permissions boundaries
    cluster_version                 = var.eks_config_opts.cluster_version
    cluster_addons                  = []
    cluster_endpoint_public_access  = false //No public access
    cluster_endpoint_private_access = true  //Private access requred
    kms_key_administrators          = local.kms_key_admin_arns
    cluster_ip_family               = "ipv4"
    //cluster_service_ipv4_cidr                = ""
    attach_cluster_encryption_policy         = true
    cluster_endpoint_public_access_cidrs     = ["0.0.0.0/0"]
    self_managed_node_group_defaults         = {}
    self_managed_node_groups                 = {}
    eks_managed_node_group_defaults          = {}
    eks_managed_node_groups                  = {}
    dataplane_wait_duration                  = "4m"
    cluster_timeouts                         = {}
    access_entries                           = {}
    authentication_mode                      = "API_AND_CONFIG_MAP"
    enable_cluster_creator_admin_permissions = true
    cluster_security_group_additional_rules  = {}
    cluster_additional_security_group_ids    = []
    create_cluster_security_group            = true
    cluster_security_group_id                = ""
    cluster_security_group_name              = ""
    cluster_security_group_use_name_prefix   = true
    cluster_security_group_description       = "EKS cluster security group"
    cluster_security_group_tags              = {}
    create_kms_key                           = true
    kms_key_description                      = ""
    kms_key_deletion_window_in_days          = null
    enable_kms_key_rotation                  = true
    kms_key_enable_default_policy            = true
    kms_key_owners                           = []
    kms_key_users                            = []
    kms_key_service_users                    = []
    kms_key_source_policy_documents          = []
    kms_key_override_policy_documents        = []
    kms_key_aliases                          = []
    cluster_enabled_log_types                = ["audit", "api", "authenticator"]
    create_cloudwatch_log_group              = true
    cloudwatch_log_group_retention_in_days   = 90
    cloudwatch_log_group_kms_key_id          = ""
    //cloudwatch_log_group_class                 = ""
    cluster_tags                               = {}
    create_cluster_primary_security_group_tags = true
    cloudwatch_log_group_tags                  = {}
  }
  il4_eks_overrides = {}
  il5_eks_overrides = merge(local.il4_eks_overrides, {}) // Base is default for IL5

  // Overrides for Developer Experiance (devx). These facilate faster setup/teardown 
  // and more open access for bundle development.
  devx_eks_overrides = {
    subnet_ids                      = var.vpc_config.subnet_ids //Public subnets for devX
    control_plane_subnet_ids        = var.vpc_config.private_subnet_ids
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

module "aws_eks" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v20.24.0"

  cluster_name             = local.eks_config.cluster_name
  cluster_version          = local.eks_config.cluster_version
  vpc_id                   = local.eks_config.vpc_id
  subnet_ids               = local.eks_config.subnet_ids
  control_plane_subnet_ids = local.eks_config.control_plane_subnet_ids
  cluster_ip_family        = local.eks_config.cluster_ip_family
  //cluster_service_ipv4_cidr                = local.eks_config.cluster_service_ipv4_cidr //removed - use default
  iam_role_permissions_boundary            = local.eks_config.iam_role_permissions_boundary
  attach_cluster_encryption_policy         = local.eks_config.attach_cluster_encryption_policy
  cluster_endpoint_public_access           = local.eks_config.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs     = local.eks_config.cluster_endpoint_public_access_cidrs
  cluster_endpoint_private_access          = local.eks_config.cluster_endpoint_private_access
  self_managed_node_group_defaults         = local.eks_config.self_managed_node_group_defaults
  self_managed_node_groups                 = local.eks_config.self_managed_node_groups
  eks_managed_node_groups                  = local.eks_config.eks_managed_node_groups
  eks_managed_node_group_defaults          = local.eks_config.eks_managed_node_group_defaults
  dataplane_wait_duration                  = local.eks_config.dataplane_wait_duration
  cluster_timeouts                         = local.eks_config.cluster_timeouts
  cluster_addons                           = local.eks_config.cluster_addons
  access_entries                           = local.eks_config.access_entries
  authentication_mode                      = local.eks_config.authentication_mode
  enable_cluster_creator_admin_permissions = local.eks_config.enable_cluster_creator_admin_permissions

  #----------------------------------------------------------------------------------------------------------#
  #   Security groups used in this module created by the upstream modules terraform-aws-eks (https://github.com/terraform-aws-modules/terraform-aws-eks).
  #   Upstream module implemented Security groups based on the best practices doc https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html.
  #   By default the security groups are restrictive. Users needs to enable rules for specific ports required for App requirement or Add-ons
  #----------------------------------------------------------------------------------------------------------#
  cluster_security_group_additional_rules = local.eks_config.cluster_security_group_additional_rules
  cluster_additional_security_group_ids   = local.eks_config.cluster_additional_security_group_ids
  create_cluster_security_group           = local.eks_config.create_cluster_security_group
  cluster_security_group_id               = local.eks_config.cluster_security_group_id
  cluster_security_group_name             = local.eks_config.cluster_security_group_name
  cluster_security_group_use_name_prefix  = local.eks_config.cluster_security_group_use_name_prefix
  cluster_security_group_description      = local.eks_config.cluster_security_group_description
  cluster_security_group_tags             = local.eks_config.cluster_security_group_tags
  create_kms_key                          = local.eks_config.create_kms_key
  kms_key_description                     = local.eks_config.kms_key_description
  kms_key_deletion_window_in_days         = local.eks_config.kms_key_deletion_window_in_days
  enable_kms_key_rotation                 = local.eks_config.enable_kms_key_rotation
  kms_key_enable_default_policy           = local.eks_config.kms_key_enable_default_policy
  kms_key_owners                          = local.eks_config.kms_key_owners
  kms_key_administrators                  = local.eks_config.kms_key_administrators
  kms_key_users                           = local.eks_config.kms_key_users
  kms_key_service_users                   = local.eks_config.kms_key_service_users
  kms_key_source_policy_documents         = local.eks_config.kms_key_source_policy_documents
  kms_key_override_policy_documents       = local.eks_config.kms_key_override_policy_documents
  kms_key_aliases                         = local.eks_config.kms_key_aliases
  cluster_enabled_log_types               = local.eks_config.cluster_enabled_log_types
  create_cloudwatch_log_group             = local.eks_config.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days  = local.eks_config.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id         = local.eks_config.cloudwatch_log_group_kms_key_id
  //cloudwatch_log_group_class                 = local.eks_config.cloudwatch_log_group_class //removed - use default
  cluster_tags                               = local.eks_config.cluster_tags
  create_cluster_primary_security_group_tags = local.eks_config.create_cluster_primary_security_group_tags
  cloudwatch_log_group_tags                  = local.eks_config.cloudwatch_log_group_tags
  tags                                       = local.eks_config.tags

}

//Use Impact Level from context to set the default config for EKS
// This object will be used to configure the official AWS EKS module.
// Outputting for illustration purposes.
output "eks_config" {
  value = local.eks_config_contexts[data.context_config.this.values["impact_level"]]
}

output "eks_opt_config_out" { value = var.eks_config_opts }
output "context" { value = data.context_config.this }
output "eks_vpc_attrs" { value = var.vpc_config }


output "eks_sensitive_opt_config_out" {
  sensitive = true
  value     = var.eks_sensitive_config_opts
}

output "context_tags" {
  value = data.context_tags.this.tags
}

output "example_resource_name_suffix" {
  value = data.context_label.this.rendered
}
