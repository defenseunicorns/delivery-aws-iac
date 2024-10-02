terraform {
  required_providers {
    context = {
      source  = "registry.terraform.io/cloudposse/context"
      version = "~> 0.4.0"
    }
  }
}
// Context data sources that spans modules and deploys.
data "context_config" "this" {}
data "context_label" "this" {}
data "context_tags" "this" {}

// Standardize on config objects. Use `optional()` to set defaults as needed.
variable "vpc_config" {
  description = "Existing VPC configuration for EKS"
  type = object({
    vpc_id                     = string
    subnet_ids                 = list(string)
    azs                        = list(string)
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
    cluster_version = optional(string, "1.30")
  })
}

variable "eks_sensitive_config_opts" {
  sensitive = true
  type = object({
    eks_sensitive_opt1 = optional(string)
    eks_sensitive_opt2 = optional(string)
  })
}

locals {
  base_eks_config = {
    vpc_id                               = var.vpc_config.vpc_id
    subnet_ids                           = var.vpc_config.subnet_ids
    tags                                 = data.context_tags.this.tags
    cluster_name                         = data.context_label.this.rendered
    cluster_version                      = var.eks_config_opts.cluster_version
    control_plane_subnet_ids             = var.vpc_config.private_subnets
    private_subnet_ids                   = var.vpc_config.private_subnets
    iam_role_permissions_boundary        = data.context_config.this.values["PermissionsBoundry"]
    cluster_endpoint_public_access       = true
    cluster_endpoint_public_access_cidrs = []
    cluster_endpoint_private_access      = false
    self_managed_node_group_defaults     = {}
    self_managed_node_groups             = []
    cluster_addons                       = []
  }
  il4_eks_overrides = {
    cluster_endpoint_public_access  = false //No public access for >= IL4
    cluster_endpoint_private_access = true  //Private access requred for >= IL4
  }
  il5_eks_overrides = merge(local.il4_eks_overrides, {})
  il4_eks_config    = merge(local.base_eks_config, local.il4_eks_overrides)
  il5_eks_config    = merge(local.base_eks_config, local.il5_eks_overrides)
  eks_config = {
    base = local.base_eks_config,
    il4  = local.il4_eks_config,
    il5  = local.il5_eks_config
  }
}

//Use Impact Level from context to set the default config for EKS
// This object will be used to configure the official AWS EKS module.
// Outputting for illustration purposes.
output "eks_config" {
  value = local.eks_config[data.context_config.this.values["impact_level"]]
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
