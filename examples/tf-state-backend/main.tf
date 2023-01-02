locals {
  region                      = "us-east-2"  # target AWS region
  account                     = "8675309"  # target AWS account
  aws_admin_1_username        = "bob" # enables eks access & ssh access to bastion
  aws_admin_2_username        = "jane" # enables eks access & ssh access to bastion
  cluster_key_admin_arns      = ["arn:aws:iam::${local.account}:user/${local.aws_admin_1_username}","arn:aws:iam::${local.account}:user/${local.aws_admin_2_username}"]   # list of admin's AWS account arn to allow control of KMS keys
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
