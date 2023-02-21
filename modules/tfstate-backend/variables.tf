variable "region" {
  description = "DEPRECATED - AWS Region"
  type        = string
}

variable "bucket_prefix" {
  description = "DEPRECATED - S3 Bucket Prefix"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DEPRECATED - DynamoDB Table Name"
  type        = string
}

variable "versioning_enabled" {
  description = "DEPRECATED - Enable versioning on the S3 bucket"
  type        = bool
  default     = true
}

variable "cluster_key_admin_arns" {
  description = "DEPRECATED - ARNs of IAM users or roles that can administer the cluster"
  type        = list(string)
  default     = []
}

variable "permissions_boundary" {
  description = "DEPRECATED - (Optional) The ARN of the policy that is used to set the permissions boundary for the role."
  type        = string
  default     = ""
}
