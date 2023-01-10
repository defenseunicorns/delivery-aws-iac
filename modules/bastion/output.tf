output "instance_id" {
  value       = aws_instance.application.id
  description = "Instance Id"
}

output "private_ip" {
  value       = aws_instance.application.private_ip
  description = "Private IP"
}

output "public_ip" {
  value       = aws_instance.application.public_ip
  description = "Public IP"
}

output "primary_network_interface_id" {
  value       = aws_instance.application.primary_network_interface_id
  description = "Primary Network Interface Id"
}
output "security_group_ids" {
  value       = length(local.security_group_configs) > 0 ? aws_security_group.sg.*.id : var.security_group_ids
  description = "Security Group Ids"
}

output "access_bucket_name" {
  value       = aws_s3_bucket.access_log_bucket.id
  description = "Access Bucket Name"
}

output "access_bucket_arn" {
  value       = aws_s3_bucket.access_log_bucket.arn
  description = "Access Bucket ARN"
}

output "session_logs_bucket_name" {
  value       = aws_s3_bucket.session_logs_bucket.id
  description = "Session Logs Bucket Name"
}

output "session_logs_bucket_arn" {
  value       = aws_s3_bucket.session_logs_bucket.arn
  description = "Session Logs Bucket ARN"
}

output "private_key" {
  value     = tls_private_key.bastion_key.private_key_pem
  sensitive = true
}