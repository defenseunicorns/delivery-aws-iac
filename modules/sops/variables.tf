variable "region" {
  type        = string
  description = "AWS region"
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster"
}

variable "policy_name_prefix" {
  type        = string
  description = "Prefix for the policy name"
  default     = "sops"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

variable "irsa_sops_iam_role_name" {
  type        = string
  description = "Name of the IAM role for the Kubernetes service account"
  default     = null
}

variable "kubernetes_service_account" {
  type        = string
  description = "Name of the Kubernetes service account"
  default     = ""
}

variable "kubernetes_namespace" {
  type        = string
  description = "Name of the Kubernetes namespace"
  default     = ""
}

variable "eks_oidc_provider_arn" {
  type        = string
  description = "ARN of the OIDC provider"
  default     = ""
}

variable "irsa_iam_role_path" {
  type        = string
  description = "Path of the IAM role for the Kubernetes service account"
  default     = "/"
}

variable "irsa_iam_permissions_boundary" {
  type        = string
  description = "Permissions boundary for the IAM role for the Kubernetes service account"
  default     = ""
}

variable "sops_iam_policies" {
  type        = list(string)
  description = "IAM Policies for IRSA IAM role"
  default     = []
}

variable "kms_key_alias" {
  type        = string
  description = "KMS key alias"
  default     = "sops"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
  default     = ""
}
