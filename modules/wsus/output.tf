output "wsus_sg_id" {
  value = aws_security_group.wsus.id
}

output "wsus_private_ip" {
  value = aws_instance.wsus.private_ip
}

output "wsus_instance_id" {
  value = aws_instance.wsus.id
}
