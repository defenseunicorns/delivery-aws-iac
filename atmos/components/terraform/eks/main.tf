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

variable "eks_required_var1" {}
variable "eks_required_var2" {}
variable "eks_sensitive_required_var1" {
  sensitive = true
}
variable "eks_config_opts" {
  type = object({
    eks_opt1 = optional(string)
    eks_opt2 = optional(string)
  })
}
variable "eks_sensitive_config_opts" {
  sensitive = true
  type = object({
    eks_sensitive_opt1 = optional(string)
    eks_sensitive_opt2 = optional(string)
  })
}


output "context" { value = data.context_config.this }

output "eks_required_out1" {
  value = var.eks_required_var1
}

output "eks_required_out2" {
  value = var.eks_required_var2
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
