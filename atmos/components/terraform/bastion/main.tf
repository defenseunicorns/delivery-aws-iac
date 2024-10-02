terraform {
  required_providers {
    context = {
      source  = "registry.terraform.io/cloudposse/context"
      version = "~> 0.4.0"
    }
  }
}


# This module shall be vendored in via atmos vendor workflow.
# Guiding principles:
# * Defense Unicorns wrapper for existing official modules from Amazon
# * Common interface via variable classes. Make it obvious to the consumer what is required and what is senstive. Senstive info if combined with non-senstive will mask non-senstive info in deployment output, complicating troubleshooting.
#   * top level vars for non-senstive required inputs (no default values, validation desired)
#   * top level vars for senstive required inputs (no default values, validation desired)
#   * single top level config object for non-senstive optional inputs (default values required, validation desired)
#   * single top level config object for senstive optional inputs (default values required, validation desired)
# * perfer distinct smaller modules as part of an assembly over complex conditinal logic to statify all Impact Level requirements
# * context provider for common config, tags and labels
# * 
data "context_config" "this" {}
data "context_label" "this" {}
data "context_tags" "this" {}

variable "bastion_required_var1" {}
variable "bastion_required_var2" {}
variable "bastion_sensitive_required_var1" {
  sensitive = true
}
variable "bastion_config_opts" {
  type = object({
    bastion_opt1 = optional(string)
    bastion_opt2 = optional(string)
  })
}
variable "bastion_sensitive_config_opts" {
  sensitive = true
  type = object({
    bastion_sensitive_opt1 = optional(string)
    bastion_sensitive_opt2 = optional(string)
  })
}



output "bastion_required_out1" {
  value = var.bastion_required_var1
}

output "bastion_required_out2" {
  value = var.bastion_required_var2
}

output "bastion_sensitive_required_out1" {
  sensitive = true
  value     = var.bastion_sensitive_required_var1
}

output "bastion_opt_config_out" {
  value = var.bastion_config_opts
}
output "bastion_sensitive_opt_config_out" {
  sensitive = true
  value     = var.bastion_sensitive_config_opts
}

output "context" { value = data.context_config.this }

output "context_tags" {
  value = data.context_tags.this
}

output "example_resource_name_suffix" {
  value = data.context_label.this.rendered
}
