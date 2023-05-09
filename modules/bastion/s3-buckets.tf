#####################################################
##################### S3 Bucket #####################

# Create S3 bucket for session logs with versioning, encryption, blocked public access enabled
resource "aws_s3_bucket" "session_logs_bucket" {
  # checkov:skip=CKV_AWS_144: Cross region replication overkill
  bucket_prefix = "${var.session_log_bucket_name_prefix}-"
  force_destroy = true
  tags          = var.tags

}

resource "aws_s3_bucket_logging" "access_logging_on_session_logs_bucket" {
  bucket = aws_s3_bucket.session_logs_bucket.id

  target_bucket = data.aws_s3_bucket.access_logs_bucket.id
  target_prefix = var.access_logs_target_prefix
}

resource "aws_s3_bucket_acl" "session_logs_bucket" {
  bucket = aws_s3_bucket.session_logs_bucket.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.session_logs_bucket
  ]
}

resource "aws_s3_bucket_ownership_controls" "session_logs_bucket" {
  bucket = aws_s3_bucket.session_logs_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [
    aws_s3_bucket.session_logs_bucket,
    aws_s3_bucket_public_access_block.session_logs_bucket
  ]
}

resource "aws_s3_bucket_versioning" "session_logs_bucket" {
  bucket = aws_s3_bucket.session_logs_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "session_logs_bucket" {
  bucket = aws_s3_bucket.session_logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = data.aws_kms_key.default.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "session_logs_bucket" {
  bucket                  = aws_s3_bucket.session_logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "session_logs_bucket" {
  bucket = aws_s3_bucket.session_logs_bucket.id

  rule {
    id     = "archive_after_X_days"
    status = "Enabled"

    transition {
      days          = var.log_archive_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.log_expire_days
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.session_logs_bucket
  ]

  rule {
    id     = "abort_incomplete_multipart_upload"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_notification" "session_logs_bucket_notification" {
  count  = var.enable_sqs_events_on_bastion_login ? 1 : 0
  bucket = aws_s3_bucket.session_logs_bucket.id

  queue {
    queue_arn = aws_sqs_queue.bastion_login_queue[0].arn
    events    = ["s3:ObjectCreated:*"]
  }
}
