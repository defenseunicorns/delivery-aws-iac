locals {
  region = "###ZARF_VAR_REGION###" # target AWS region
  account = "###ZARF_VAR_ACCOUNT###"  # target AWS account
  aws_admin_1_username = "###ZARF_VAR_AWS_ADMIN_1_USERNAME###" # enables eks access & ssh access to bastion
  aws_admin_2_username = "###ZARF_VAR_AWS_ADMIN_2_USERNAME###" # enables eks access & ssh access to bastion
  cluster_key_admin_arns      = ["arn:aws:iam::${local.account}:user/${local.aws_admin_1_username}","arn:aws:iam::${local.account}:user/${local.aws_admin_2_username}"]   # list of admin's AWS account arn to allow control of KMS keys
}

provider "aws" {
  region = local.region
}

module "tfstate_backend" {
  source = "git::https://github.com/defenseunicorns/iac.git//modules/tfstate-backend?ref=v0.0.0-alpha.0"

  region                 = local.region
  bucket_prefix          = "my-tfstate-backend"
  dynamodb_table_name    = "my-tfstate-backend-lock"
  cluster_key_admin_arns = local.cluster_key_admin_arns
}

output "tfstate_bucket_id" {
  value       = module.tfstate_backend.tfstate_bucket_id
  description = "Terraform State Bucket Name"
}
