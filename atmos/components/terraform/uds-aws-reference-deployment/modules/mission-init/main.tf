data "aws_region" "current" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  # This data source provides information on the IAM source role of an STS assumed role
  # For non-role ARNs, this data source simply passes the ARN through issuer ARN
  # Ref https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2327#issuecomment-1355581682
  # Ref https://github.com/hashicorp/terraform-provider-aws/issues/28381
  arn = data.aws_caller_identity.current.arn
}


//At init provide context for selection of azs
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
  //TODO: can we filter based on EKS and Bastion capabitlity needs (i.e.: ses_vpce)
}

//TODO: amis shall be set in eks and bastion modules w/o support for overrides.
data "aws_ami" "init" {
  for_each    = var.ami_filters
  owners      = each.value.owners
  most_recent = each.value.most_recent
  dynamic "filter" {
    for_each = each.value.filters
    content {
      name   = filter.key
      values = filter.value
    }
  }
}
