terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.72.0"
    }
  }
  required_version = ">= 0.13"
}

provider "aws" {
  region = var.aws_region
}
