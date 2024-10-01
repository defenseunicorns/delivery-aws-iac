terraform {
  required_providers {
    context = {
      source  = "registry.terraform.io/cloudposse/context"
      version = "~> 0.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}


resource "random_id" "deploy_id" {
  byte_length = 2
}

# Configure the Context Provider
provider "context" {}
data "context_config" "this" {}
# Create a Label
data "context_label" "this" {}
# Create Tags
data "context_tags" "this" {}

output "context_config" {
  value = data.context_config.this
}
output "context_label" {
  value = data.context_label.this
}

output "context_tags" {
  value = data.context_tags.this
}

output "deploy_id" {
  value = random_id.deploy_id.hex
}
