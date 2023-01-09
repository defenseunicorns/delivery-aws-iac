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

output "bucket_name" {
  value       = aws_s3_bucket.b.id
  description = "Bucket Name"
}

output "bucket_arn" {
  value       = aws_s3_bucket.b.arn
  description = "Bucket ARN"
}

output "private_key" {
  value     = tls_private_key.bastion_key.private_key_pem
  sensitive = true
}