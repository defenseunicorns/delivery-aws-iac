locals {
  s3_bucket_prefix                         = "${var.name}-cloudtrail"
  cloudtrail_cloudwatch_role_name_prefix   = "${var.name}-cloudtrail-to-cloudwatch"
  cloudtrail_cloudwatch_policy_name_prefix = "${var.name}-cloudtrail-to-cloudwatch"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_kms_key" "this" {
  key_id = var.kms_key_id
}

resource "aws_cloudtrail" "this" {
  # checkov:skip=CKV_AWS_252: "Ensure CloudTrail defines an SNS Topic" -- SNS not currently needed
  name                       = var.name
  s3_key_prefix              = var.s3_key_prefix
  s3_bucket_name             = var.use_external_s3_bucket ? var.s3_bucket_name : aws_s3_bucket.this[0].id
  kms_key_id                 = data.aws_kms_key.this.arn
  is_multi_region_trail      = var.is_multi_region_trail
  enable_log_file_validation = true
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.this.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_role.arn
  tags                       = var.tags

  depends_on = [
    aws_s3_bucket_policy.this
  ]
}
