terraform {
  required_providers {
    context = {
      source  = "registry.terraform.io/cloudposse/context"
      version = "~> 0.4.0"
    }
  }
}
data "context_config" "this" {}
data "context_label" "this" {}
data "context_tags" "this" {}

variable "vpc_attrs" {
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
variable "eks_config_opts" {
  type = object({
    cluster_version = optional(string, "1.30")
  })
}
variable "eks_sensitive_required_var1" {
  sensitive = true
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
    vpc_id                               = var.vpc_attrs.vpc_id
    subnet_ids                           = var.vpc_attrs.subnet_ids
    tags                                 = data.context_tags.this.tags
    cluster_name                         = data.context_label.this.rendered
    cluster_version                      = var.eks_config_opts.cluster_version
    control_plane_subnet_ids             = var.vpc_attrs.private_subnets
    private_subnet_ids                   = var.vpc_attrs.private_subnets
    iam_role_permissions_boundary        = data.context_config.this.values["PermissionsBoundry"]
    cluster_endpoint_public_access       = false
    cluster_endpoint_public_access_cidrs = []
    cluster_endpoint_private_access      = true
    self_managed_node_group_defaults     = {}
    self_managed_node_groups             = []
    cluster_addons                       = []
  }
  il4_eks_config = merge(local.base_eks_config, {})
  il5_eks_config = merge(local.il4_eks_config, {})
  eks_config = {
    il4 = local.il4_eks_config,
    il5 = local.il5_eks_config
  }
}


output "context" { value = data.context_config.this }

output "eks_vpc_attrs" {
  value = var.vpc_attrs
}

output "eks_config" {
  value = local.eks_config[data.context_config.this.values["impact_level"]]
}

output "eks_sensitive_required_out1" {
  sensitive = true
  value     = var.eks_sensitive_required_var1
}

output "eks_opt_config_out" {
  value = var.eks_config_opts
}
output "eks_sensitive_opt_config_out" {
  sensitive = true
  value     = var.eks_sensitive_config_opts
}

output "context_tags" {
  value = data.context_tags.this
}

output "example_resource_name" {
  value = data.context_label.this.rendered
}
