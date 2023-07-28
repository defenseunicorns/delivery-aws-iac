# TODO: Evaluate whether this should all go into a new module

# Create a KMS key and corresponding alias. This KMS key will be used whenever encryption is needed in creating this infrastructure deployment
resource "aws_kms_key" "default" {
  description             = "SSM Key"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_access.json
  tags                    = local.tags
  multi_region            = true
}

resource "aws_kms_alias" "default" {
  name_prefix   = local.kms_key_alias_name_prefix
  target_key_id = aws_kms_key.default.key_id
}

# Create custom policy for KMS
data "aws_iam_policy_document" "kms_access" {
  # checkov:skip=CKV_AWS_111: todo reduce perms on key
  # checkov:skip=CKV_AWS_109: todo be more specific with resources
  # checkov:skip=CKV_AWS_356: todo be more specific with kms resources
  statement {
    sid = "KMS Key Default"
    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "kms:*",
    ]

    resources = ["*"]
  }
  statement {
    sid = "CloudWatchLogsEncryption"
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]

    resources = ["*"]
  }
  statement {
    sid = "Cloudtrail KMS permissions"
    principals {
      type = "Service"
      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]
  }
}

# Create S3 bucket for access logs with versioning, encryption, blocked public access enabled
resource "aws_s3_bucket" "access_log_bucket" {
  # checkov:skip=CKV_AWS_144: Cross region replication is overkill
  # checkov:skip=CKV_AWS_18: "Ensure the S3 bucket has access logging enabled" -- This is the access logging bucket. Logging to the logging bucket would cause an infinite loop.
  bucket_prefix = local.access_logging_name_prefix
  force_destroy = true
  tags          = local.tags

  lifecycle {
    precondition {
      condition     = length(local.access_logging_name_prefix) <= 37
      error_message = "Bucket name prefixes may not be longer than 37 characters."
    }
  }
}

resource "aws_s3_bucket_versioning" "access_log_bucket" {
  bucket = aws_s3_bucket.access_log_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_log_bucket" {
  bucket = aws_s3_bucket.access_log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.default.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_log_bucket" {
  bucket                  = aws_s3_bucket.access_log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "access_log_bucket" {
  bucket = aws_s3_bucket.access_log_bucket.id

  rule {
    id     = "delete_after_X_days"
    status = "Enabled"

    expiration {
      days = var.access_log_expire_days
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

resource "aws_sqs_queue" "access_log_queue" {
  count                             = var.enable_sqs_events_on_access_log_access ? 1 : 0
  name                              = local.access_log_sqs_queue_name
  kms_master_key_id                 = aws_kms_key.default.arn
  kms_data_key_reuse_period_seconds = 300
  visibility_timeout_seconds        = 300

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSend",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:${data.aws_partition.current.partition}:sqs:*:*:${local.access_log_sqs_queue_name}",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.access_log_bucket.arn}" }
      }
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_notification" "access_log_bucket_notification" {
  count  = var.enable_sqs_events_on_access_log_access ? 1 : 0
  bucket = aws_s3_bucket.access_log_bucket.id

  queue {
    queue_arn = aws_sqs_queue.access_log_queue[0].arn
    events    = ["s3:ObjectCreated:*"]
  }
}
