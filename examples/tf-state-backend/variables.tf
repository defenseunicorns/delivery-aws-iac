variable "region" {
  description = "AWS region"
  type        = string
}

variable "account" {
  description = "AWS account"
  type        = string
}

variable "aws_admin_usernames" {
  description = "A list of one or more AWS usernames with authorized access to KMS and EKS resources"
  type        = list(string)
}

variable "bucket_prefix" {
  type    = string
  default = "my-tfstate-backend"
}

variable "dynamodb_table_name" {
  type    = string
  default = "my-tfstate-backend-lock"
}
