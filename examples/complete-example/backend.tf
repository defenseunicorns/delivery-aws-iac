terraform {
  backend "s3" {
    region         = "us-east-2"
    bucket         = "my-tfstate-backend-bucket-id"
    key            = "complete-example/terraform.tfstate"
    dynamodb_table = "my-tfstate-backend-lock"
    profile        = ""
    role_arn       = ""
    encrypt        = "true"
  }
}
