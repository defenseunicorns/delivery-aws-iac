provider "aws" {
  default_tags {
    tags = {
      PermissionsBoundary = split("/", var.permissions_boundary_policy_arn)[1]
    }
  }
}
