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
variable "azs" {
  type        = list(string)
  description = "VPC availablity zones - Must select based on downstream resource capabilities."
}
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

output "vpc_attrs" {
  value = {
    vpc_id             = "test-vpc-id"
    subnet_ids         = ["subnet-01", "subnet-02"]
    azs                = ["us-east-1a", "us-east-1b"]
    private_subnet_ids = ["private-subnet-01", "private-subnet-02"]
    intra_subnet_ids   = ["intra-subnet-01", "intra-subnet-02"]
  }
}

output "example_resource_name" {
  value = data.context_label.this.rendered
}
