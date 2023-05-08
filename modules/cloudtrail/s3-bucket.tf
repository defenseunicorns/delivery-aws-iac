resource "aws_s3_bucket" "this" {
  # checkov:skip=CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled" -- Cross-region replication is not necessary
  # checkov:skip=CKV_AWS_18: "Ensure the S3 bucket has access logging enabled" -- Access logging is overkill if we are creating our own bucket. Best Practice is to send CloudTrail logs to a bucket in a different account.
  # checkov:skip=CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled" -- False positive
  # checkov:skip=CKV2_AWS_6: "Ensure that S3 bucket has a Public Access block" -- False positive
  # checkov:skip=CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default" -- False positive
  # checkov:skip=CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled" -- Not necessary for this bucket
  # checkov:skip=CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration" -- False positive
  count         = var.use_external_s3_bucket ? 0 : 1
  bucket_prefix = local.s3_bucket_prefix
  force_destroy = true
  tags          = var.tags
  # Bucket prefix can't be longer than 37 characters
  lifecycle {
    precondition {
      condition     = length(local.s3_bucket_prefix) <= 37
      error_message = "The bucket prefix must be less than 37 characters."
    }
  }
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
    resources = [aws_s3_bucket.this[0].arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.name}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this[0].arn}/${var.s3_key_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.name}"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count  = var.use_external_s3_bucket ? 0 : 1
  bucket = aws_s3_bucket.this[0].id
  policy = data.aws_iam_policy_document.this[0].json
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.use_external_s3_bucket ? 0 : 1
  bucket = aws_s3_bucket.this[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.use_external_s3_bucket ? 0 : 1
  bucket = aws_s3_bucket.this[0].id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = data.aws_kms_key.this.id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count                   = var.use_external_s3_bucket ? 0 : 1
  bucket                  = aws_s3_bucket.this[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.use_external_s3_bucket ? 0 : 1
  bucket = aws_s3_bucket.this[0].id
  rule {
    id     = "delete_after_X_days"
    status = "Enabled"
    expiration {
      days = var.log_retention_days
    }
  }
  rule {
    id     = "abort_incomplete_multipart_upload"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
