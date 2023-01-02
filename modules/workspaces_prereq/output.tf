output "directory_service_id" {
  value = aws_directory_service_directory.main.id
}

output "directory_service_ips" {
  value = aws_directory_service_directory.main.dns_ip_addresses
}

output "workspace_directory_id" {
  value = aws_workspaces_directory.main.id
}