terraform {
  backend "s3" {
    region         = "us-east-2"
    bucket         = ""
    key            = ""
    dynamodb_table = ""
    profile        = ""
    role_arn       = ""
    encrypt        = "true"
  }
}
