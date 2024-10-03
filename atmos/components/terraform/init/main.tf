terraform {
  required_providers {
    context = {
      source  = "registry.terraform.io/cloudposse/context"
      version = "~> 0.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}


variable "availabity_zones_excludes" {
  type        = list(string)
  description = "list of az to exclude from context driven selection"
  default     = []
}
resource "random_id" "deploy_id" {
  byte_length = 2
}

# Configure the Context Provider
provider "context" {}
data "context_config" "this" {}
# Create a Label
data "context_label" "this" {}
# Create Tags
data "context_tags" "this" {}

//At init provide context for selection of azs
/*
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
  //TODO: can we filter based on EKS and Bastion capabitlity needs (i.e.: ses_vpce)
  exclude_names = var.availabity_zones_excludes
}
*/

locals {
  tmp_az = ["az-1", "az-2"]
}

output "context_config" {
  value = data.context_config.this
}
output "context_label" {
  value = data.context_label.this
}

output "context_tags" {
  value = data.context_tags.this
}

output "deploy_id" {
  value = random_id.deploy_id.hex
}
output "azs" {
  //value = data.aws_availability_zones.available.names
  value = local.tmp_az
}
