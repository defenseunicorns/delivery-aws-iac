variable "region" {
  description = "AWS region"
  type        = string
}

variable "account" {
  description = "AWS account"
  type        = string
}

variable "aws_admin_usernames" {
  description = "A list of one or more AWS usernames with authorized access to KMS and EKS resources, will automatically add the user running the terraform as an admin"
  type        = list(string)
  default     = []
}

variable "bucket_prefix" {
  type    = string
  default = "my-tfstate-backend"
}

variable "dynamodb_table_name" {
  type    = string
  default = "my-tfstate-backend-lock"
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "default_tags" {
  description = "A map of default tags to apply to all resources"
  type        = map(string)
  default     = {}
}
