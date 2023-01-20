provider "aws" {
  region = var.region
}

data "aws_partition" "current" {}

module "tfstate_backend" {
  source = "git::https://github.com/defenseunicorns/iac.git//modules/tfstate-backend?ref=v0.0.0-alpha.1"

  region                 = var.region
  bucket_prefix          = "my-tfstate-backend"
  dynamodb_table_name    = "my-tfstate-backend-lock"

  # list of admin's AWS account arn to allow control of KMS keys
  cluster_key_admin_arns = ["arn:${data.aws_partition.current.partition}:iam::${var.account}:user/${var.aws_admin_1_username}","arn:${data.aws_partition.current.partition}:iam::${var.account}:user/${var.aws_admin_2_username}"]
}

output "tfstate_bucket_id" {
  value       = module.tfstate_backend.tfstate_bucket_id
  description = "Terraform State Bucket Name"
}
