output "instance_id" {
  value       = aws_instance.application.id
  description = "Instance Id"
}

output "private_ip" {
  value       = aws_instance.application.private_ip
  description = "Private IP"
}

output "private_dns" {
  value       = aws_instance.application.private_dns
  description = "Private DNS"
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
  value       = length(local.security_group_configs) > 0 ? aws_security_group.sg[*].id : var.security_group_ids
  description = "Security Group Ids"
}

output "session_logs_bucket_name" {
  value       = aws_s3_bucket.session_logs_bucket.id
  description = "Session Logs Bucket Name"
}

output "session_logs_bucket_arn" {
  value       = aws_s3_bucket.session_logs_bucket.arn
  description = "Session Logs Bucket ARN"
}

output "bastion_role_name" {
  value       = aws_iam_role.bastion_ssm_role.name
  description = "Bastion Role Name"
}

output "bastion_role_arn" {
  value       = aws_iam_role.bastion_ssm_role.arn
  description = "Bastion Role ARN"
}

output "region" {
  value       = data.aws_region.current.name
  description = "Region the bastion was deployed to"
}
