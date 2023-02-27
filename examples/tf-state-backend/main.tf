provider "aws" {
  region = var.region
}

data "aws_partition" "current" {}

locals {
  admin_arns = [for admin in var.aws_admin_usernames : "arn:${data.aws_partition.current.partition}:iam::${var.account}:user/${admin}"]
}

module "tfstate_backend" {
  source = "git::https://github.com/defenseunicorns/terraform-aws-tfstate-backend.git?ref=0.0.1"

  region              = var.region
  bucket_prefix       = var.bucket_prefix
  dynamodb_table_name = var.dynamodb_table_name

  # list of admin's AWS account arn to allow control of KMS keys
  cluster_key_admin_arns = local.admin_arns
}

output "tfstate_bucket_id" {
  value       = module.tfstate_backend.tfstate_bucket_id
  description = "Terraform State Bucket Name"
}

output "tfstate_dynamodb_table_name" {
  value       = module.tfstate_backend.tfstate_dynamodb_table_name
  description = "Terraform State Bucket Name"
}
