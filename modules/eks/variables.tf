# tflint-ignore: terraform_unused_declarations
variable "cluster_name" {
  description = "Name of cluster - used by Terratest for e2e test automation"
  type        = string
  default     = ""
}

variable "eks_k8s_version" {
  description = "Kubernetes version to use for EKS cluster"
  type        = string
  default     = "1.23"
}

 variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
 }

 variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
  default     = []
 }

 variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
  default     = []
 }

variable "aws_region" {
  type    = string
  default = ""
}

variable "aws_account" {
  type    = string
  default = ""
}

variable "name" {
  type    = string
  default = ""
}

variable "aws_auth_eks_map_users" {
  description = "List of map of users to add to aws-auth configmap"
  type        = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default     = []
}

variable "cluster_kms_key_additional_admin_arns" {
  description = "List of ARNs of additional users to add to KMS key policy"
  type        = list(string)
  default     = []
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to the cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the cluster endpoint"
  type        = bool
  default     = false
}

variable "control_plane_subnet_ids" {
  description = "Subnet IDs for control plane"
  type        = list(string)
  default     = []
}

variable "source_security_group_id" {
  description = "List of additional rules to add to cluster security group"
  type        = string
  default     = ""
}

# variable "manage_aws_auth_configmap" {
#   description = "Whether to manage the aws-auth configmap"
#   type        = bool
#   default     = true
# }
