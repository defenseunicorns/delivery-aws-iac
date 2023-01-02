resource "aws_kms_key" "ws_volume_encryption" {
  description             = "KMS key for Workspaces volume encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_workspaces_workspace" "workspace" {
  for_each = var.ws_config

  directory_id = var.directory_id
  bundle_id    = each.value.bundle_id
  user_name    = each.value.user_name

  root_volume_encryption_enabled = true
  user_volume_encryption_enabled = true
  volume_encryption_key          = aws_kms_key.ws_volume_encryption.arn

  workspace_properties {
    compute_type_name                         = each.value.compute_type_name
    user_volume_size_gib                      = each.value.user_volume_size_gib
    root_volume_size_gib                      = each.value.root_volume_size_gib
    running_mode                              = each.value.running_mode
    running_mode_auto_stop_timeout_in_minutes = each.value.running_mode_auto_stop_timeout_in_minutes
  }

  tags = var.common_tags
}