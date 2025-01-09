variable "deploy_id" {
  description = "A unique identifier for the deployment"
  type        = string
}

variable "permissions_boundary_policy_arn" {
  description = "The ARN of the permissions boundary to be applied to roles"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}
