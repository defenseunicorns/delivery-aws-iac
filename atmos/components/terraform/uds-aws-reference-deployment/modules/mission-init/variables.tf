# Required
variable "deploy_id" {
  type        = string
  description = "A unique identifier for the deployment"
}

variable "permissions_boundary_policy_arn" {
  description = "The ARN of the permissions boundary to be applied to roles"
  type        = string
}
# Optional
variable "stage" {
  type        = string
  default     = "demo"
  description = "The deployment stage, i.e. dev, test, staging etc..."
}

variable "impact_level" {
  type        = string
  default     = "devx"
  description = "The impact level configuration to use for deployment, i.e. devx, il5, etc.."
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
        name = ["bottlerocket-aws-k8s-1.29-x86_64-v1.23.0-74970be4"]
      }
    }
    bastion = {
      owners      = ["amazon"]
      most_recent = true
      filters = {
        "name" = ["al2023-ami-20*-kernel-*-x86_64"]
      }
    }
  }
}
