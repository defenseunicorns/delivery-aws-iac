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
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34"
    }
  }
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  # This data source provides information on the IAM source role of an STS assumed role
  # For non-role ARNs, this data source simply passes the ARN through issuer ARN
  # Ref https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2327#issuecomment-1355581682
  # Ref https://github.com/hashicorp/terraform-provider-aws/issues/28381
  arn = data.aws_caller_identity.current.arn
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
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
  //TODO: can we filter based on EKS and Bastion capabitlity needs (i.e.: ses_vpce)
  exclude_names = var.availabity_zones_excludes
}

locals {
  iam_role_permissions_boundary_policy_name = lookup(data.context_config.this.values, "permissions_boundary_policy_name", null)
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
  value = data.aws_availability_zones.available.names
}
output "permissions_boundary_policy_arn" {
  value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.iam_role_permissions_boundary_policy_name}"
}
output "permissions_boundary_policy_name" {
  value = local.iam_role_permissions_boundary_policy_name
}

output "aws_partition" {
  value = data.aws_partition.current
}
output "aws_caller_identity" {
  value = data.aws_caller_identity.current
}
output "aws_iam_session_context" {
  value = data.aws_iam_session_context.current
}
