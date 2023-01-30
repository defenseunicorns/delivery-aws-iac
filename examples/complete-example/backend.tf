terraform {
  backend "s3" {
    region         = ""
    bucket         = ""
    key            = ""
    dynamodb_table = ""
    profile        = ""
    role_arn       = ""
    encrypt        = "true"
  }
}
