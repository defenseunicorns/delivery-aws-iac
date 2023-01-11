#####################################################
##################### S3 Bucket #####################

# Create S3 bucket for access logs with versioning, encryption, blocked public acess enabled
resource "aws_s3_bucket" "access_log_bucket" {
  # checkov:skip=CKV_AWS_144: Cross region replication is overkill
  bucket_prefix = "${var.access_log_bucket_name}-"
  force_destroy = true

  tags = var.tags
}

resource "aws_s3_bucket_acl" "access_log_bucket" {
  bucket = aws_s3_bucket.access_log_bucket.id

  acl = "log-delivery-write"
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
      kms_master_key_id = aws_kms_key.ssmkey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# resource "aws_s3_bucket_logging" "access_logging_bucket" {
#   bucket = aws_s3_bucket.session_logs_bucket.id

#   target_bucket = aws_s3_bucket.access_log_bucket.id
#   target_prefix = "log/"
# }

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
}

resource "aws_s3_bucket_notification" "access_log_bucket_notification" {
  count  = var.enable_event_queue ? 1 : 0
  bucket = aws_s3_bucket.access_log_bucket.id

  queue {
    queue_arn = aws_sqs_queue.queue[0].arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# resource "aws_s3_object" "ssh_public_keys" {
#   # Make sure that you put files into correct location and name them accordingly (`public-keys/{keyname}.pub`)
#   source     = "./public-keys/${element(var.ssh_public_key_names, count.index)}.pub"
#   depends_on = [aws_s3_bucket.b]

#   count = length(var.ssh_public_key_names)

#   bucket = aws_s3_bucket.b.bucket
#   key    = "${element(var.ssh_public_key_names, count.index)}.pub"
# }

# Create S3 bucket for session logs with versioning, encryption, blocked public acess enabled
resource "aws_s3_bucket" "session_logs_bucket" {
  # checkov:skip=CKV_AWS_144: Cross region replication overkill
  bucket_prefix = "${var.bucket_name}-"
  force_destroy = true
  tags          = var.tags

}

resource "aws_s3_bucket_acl" "session_logs_bucket" {
  bucket = aws_s3_bucket.session_logs_bucket.id

  acl = "private"
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
      kms_master_key_id = aws_kms_key.ssmkey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "session_logs_bucket" {
  bucket = aws_s3_bucket.session_logs_bucket.id

  target_bucket = aws_s3_bucket.session_logs_bucket.id
  target_prefix = "log/"
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
}

resource "aws_s3_bucket_notification" "session_logs_bucket_notification" {
  count  = var.enable_event_queue ? 1 : 0
  bucket = aws_s3_bucket.session_logs_bucket.id

  queue {
    queue_arn = aws_sqs_queue.queue[0].arn
    events    = ["s3:ObjectCreated:*"]
  }
}
