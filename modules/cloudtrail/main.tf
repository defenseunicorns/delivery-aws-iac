locals {
  cloudtrail_s3_bucket_name = var.use_external_s3_bucket ? var.s3_bucket_name : aws_s3_bucket.this.id
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "this" {
  count         = var.use_external_s3_bucket ? 0 : 1
  bucket_prefix = var.name
  force_destroy = true
  tags          = var.tags
}

data "aws_iam_policy_document" "this" {
  count = var.use_external_s3_bucket ? 0 : 1
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.this[*].arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this[*].arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count  = var.use_external_s3_bucket ? 0 : 1
  bucket = aws_s3_bucket.this[*].id
  policy = data.aws_iam_policy_document.this[*].json
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.use_external_s3_bucket ? 0 : 1
  bucket = aws_s3_bucket.this[*].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.use_external_s3_bucket ? 0 : 1
  bucket = aws_s3_bucket.this[*].id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count                   = var.use_external_s3_bucket ? 0 : 1
  bucket                  = aws_s3_bucket.this[*].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this[*].id
  rule {
    id     = "delete_after_X_days"
    status = "Enabled"
    expiration {
      days = var.log_retention_days
    }
  }
}

resource "aws_cloudtrail" "this" {
  # checkov:skip=CKV_AWS_252: "Ensure CloudTrail defines an SNS Topic" -- SNS not currently needed
  name                       = var.name
  s3_bucket_name             = local.cloudtrail_s3_bucket_name
  kms_key_id                 = var.kms_key_id
  is_multi_region_trail      = var.is_multi_region_trail
  enable_log_file_validation = true
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
  tags = var.tags
}
