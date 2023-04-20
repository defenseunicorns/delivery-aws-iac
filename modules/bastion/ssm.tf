resource "aws_ssm_document" "session_manager_prefs" {
  name            = "${var.name}-SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"
  tags            = var.tags


  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Document to hold regional settings for Session Manager"
    sessionType   = "Standard_Stream"
    inputs = {
      s3BucketName                = var.enable_log_to_s3 ? aws_s3_bucket.session_logs_bucket.id : ""
      s3EncryptionEnabled         = var.enable_log_to_s3 ? true : false
      cloudWatchLogGroupName      = var.enable_log_to_cloudwatch ? aws_cloudwatch_log_group.session_manager_log_group[0].name : ""
      cloudWatchEncryptionEnabled = var.enable_log_to_cloudwatch ? true : false
      kmsKeyId                    = data.aws_kms_key.default.id
      shellProfile = {
        linux   = var.linux_shell_profile == "" ? var.linux_shell_profile : ""
        windows = var.windows_shell_profile == "" ? var.windows_shell_profile : ""
      }
    }
  })
}
