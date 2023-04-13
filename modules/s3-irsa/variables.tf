variable "region" {
  description = "AWS Region"
  type        = string
  // TODO: Evaluate whether "" is ever a valid value for this variable. Does this need to be a required variable with a validation that checks against a list of known regions?
  default = ""
}

variable "name_prefix" {
  description = "Name prefix for all resources that use a randomized suffix"
  type        = string
  validation {
    condition     = length(var.name_prefix) <= 37
    error_message = "Name Prefix may not be longer than 37 characters."
  }
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

// TODO: Evaluate whether we need this to be a variable
variable "policy_name_prefix" {
  description = "IAM Policy name prefix"
  type        = string
  default     = "irsa-policy"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS Key ARN to use for encryption"
}

variable "name_dynamodb" {
  description = "Name of DynamoDB table"
  type        = string
  // TODO: Evaluate whether "" is ever a valid value for this variable.
  default = ""
}

variable "dynamodb_enabled" {
  description = "Is dynamoDB enabled"
  type        = bool
  default     = false
}

variable "access_logging_enabled" {
  description = "If true, set up access logging of the S3 bucket to a different S3 bucket, provided by the variables `logging_bucket_id` and `logging_bucket_path`. Caution: Enabling this will likely cause LOTS of access logs, as one is generated each time the bucket is accessed and Loki will be hitting the bucket a lot!"
  type        = bool
  default     = false
}

variable "access_logging_bucket_id" {
  description = "The ID of the S3 bucket to which access logs are written"
  type        = string
  default     = null
}

variable "access_logging_bucket_prefix" {
  description = "The prefix to use for all log object keys. Ex: 'logs/'"
  type        = string
  default     = "s3-irsa-bucket-access-logs/"
}
