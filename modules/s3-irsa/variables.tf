variable "region" {
  description = "AWS Region"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
  default     = ""
}

variable "irsa_iam_policies" {
  type        = list(string)
  description = "IAM Policies for IRSA IAM role"
  default     = []
}

variable "irsa_iam_role_name" {
  type        = string
  description = "IAM role name for IRSA"
  default     = ""
}

variable "irsa_iam_role_path" {
  description = "IAM role path for IRSA roles"
  type        = string
  default     = "/"
}

variable "irsa_iam_permissions_boundary" {
  description = "IAM permissions boundary for IRSA roles"
  type        = string
  default     = ""
}

variable "eks_oidc_provider_arn" {
  description = "EKS OIDC Provider ARN e.g., arn:aws:iam::<ACCOUNT-ID>:oidc-provider/<var.eks_oidc_provider>"
  type        = string
}

variable "tags" {
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
  type        = map(string)
  default     = {}
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for IRSA"
  type        = string
  default     = "default"
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account for IRSA"
  type        = string
  default     = "default"
}

variable "policy_name_prefix" {
  description = "IAM Policy name prefix"
  type        = string
  default     = "irsa-policy"
}

variable bucket_prefix {
  description = "Prefix for the S3 bucket"
  type        = string
  default     = "bigbang"
}

variable "kms_key_alias" {
  description = "KMS key alias"
  type        = string
  default     = ""
}


# variable "billing_mode" {
#   description = "A choice beetween billing mode: PAY_PER_REQUEST or PROVISIONED"
#   type = string
#   default = ""
# }

variable "name_dynamodb" {
  description = "Name of DynamoDB table"
  type = string
  default = ""
}

variable "dynamodb_enabled" {
  description = "Is dynamoDB enabled"
  type = bool
  default = false
}