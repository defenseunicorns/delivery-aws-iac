variable "region" {
  description = "AWS region"
  type        = string
}

variable "account" {
  description = "AWS account"
  type        = string
}

variable "aws_admin_1_username" {
  description = "AWS username authorized to access S3 Terraform State Backend"
  type        = string
}

variable "aws_admin_2_username" {
  description = "AWS username authorized to access S3 Terraform State Backend"
  type        = string
}
