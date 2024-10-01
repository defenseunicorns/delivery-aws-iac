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
variable "vpc_required_var1" {}
variable "vpc_required_var2" {}
variable "vpc_sensitive_required_var1" {
  sensitive = true
}
variable "vpc_config_opts" {
  type = object({
    vpc_opt1 = optional(string)
    vpc_opt2 = optional(string)
  })
}
variable "vpc_sensitive_config_opts" {
  sensitive = true
  type = object({
    vpc_sensitive_opt1 = optional(string)
    vpc_sensitive_opt2 = optional(string)
  })
}

output "context" { value = data.context_config.this }

output "vpc_required_out1" {
  value = var.vpc_required_var1
}

output "vpc_required_out2" {
  value = var.vpc_required_var2
}

output "vpc_sensitive_required_out1" {
  sensitive = true
  value     = var.vpc_sensitive_required_var1
}

output "vpc_opt_config_out" {
  value = var.vpc_config_opts
}
output "vpc_sensitive_opt_config_out" {
  sensitive = true
  value     = var.vpc_sensitive_config_opts
}

output "context_tags" {
  value = data.context_tags.this
}

output "example_resource_name" {
  value = data.context_label.this.rendered
}
