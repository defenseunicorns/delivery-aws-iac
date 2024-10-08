//providers.tf
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

provider "context" {}

//variables.tf
variable "availabity_zones_excludes" {
  type        = list(string)
  description = "list of az to exclude from context driven selection"
  default     = []
}

variable "ami_filters" {
  type = map(object({
    owners      = list(string)
    most_recent = bool
    filters     = map(list(string))
  }))
  default = {
    eks-cpu = {
      owners      = ["amazon"]
      most_recent = true
      filters = {
        //name = ["bottlerocket-aws-k8s-${var.cluster_version}-x86_64-*"] //TODO: should cluster version be included?
        name = ["bottlerocket-aws-k8s-*-x86_64-*"]
      }
    }
    eks-lfai-gpu = {
      owners      = ["amazon"]
      most_recent = true
      filters = {
        //name = ["bottlerocket-aws-k8s-${var.eks_version}-nvidia-x86_64-*"]
        name = ["bottlerocket-aws-k8s-*-nvidia-x86_64-*"]
      }
    },
    bastion = {
      owners      = ["amazon"]
      most_recent = true
      filters = {
        "name" = ["al2023-ami-20*-kernel-*-x86_64"]
      }
    }
  }
}


//main.tf
locals {
  iam_role_permissions_boundary_policy_name = lookup(data.context_config.this.values, "permissions_boundary_policy_name", null)
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


# Configure the Context Provider
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

//TODO: amis shall be set in eks and bastion modules w/o support for overrides.
data "aws_ami" "init" {
  for_each    = var.ami_filters
  owners      = each.value.owners
  most_recent = each.value.most_recent
  dynamic "filter" {
    for_each = each.value.filters
    content {
      name   = filter.key
      values = filter.value
    }
  }
}

resource "random_id" "deploy_id" {
  byte_length = 2
}

//outputs.tf
//Outputs at mission-init reflect what needs to be decided at start-of-mission
// - this can be in a tofu root module that connects our opinionated wrappers for vpc, eks, bastion or at the componet level using atmos.
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

output "amis" {
  value = {
    for key, ami in data.aws_ami.init : key => { id = ami.id }
  }
}
