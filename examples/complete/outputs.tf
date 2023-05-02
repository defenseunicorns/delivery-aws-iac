# # Root module outputs
# # Setting all of them sensitive = true to avoid having their details logged to the console in our public CI pipelines

# output "loki_s3_bucket" {
#   description = "Loki S3 Bucket Name"
#   value       = module.loki_s3_bucket.s3_bucket
#   sensitive   = true
# }

# output "keycloak_db_instance_endpoint" {
#   description = "The connection endpoint"
#   value       = try(module.rds_postgres_keycloak[0].db_instance_endpoint, null)
#   sensitive   = true
# }

# output "keycloak_db_instance_name" {
#   description = "The database name"
#   value       = try(module.rds_postgres_keycloak[0].db_instance_name, null)
#   sensitive   = true
# }

# output "keycloak_db_instance_username" {
#   description = "The master username for the database"
#   value       = try(module.rds_postgres_keycloak[0].db_instance_username, null)
#   sensitive   = true
# }

# output "keycloak_db_instance_port" {
#   description = "The database port"
#   value       = try(module.rds_postgres_keycloak[0].db_instance_port, null)
#   sensitive   = true
# }

# output "bastion_instance_id" {
#   description = "The ID of the bastion host"
#   value       = module.bastion.instance_id
#   sensitive   = true
# }

# output "bastion_region" {
#   description = "The region that the bastion host was deployed to"
#   value       = module.bastion.region
#   sensitive   = true
# }

# output "bastion_private_dns" {
#   description = "The private DNS address of the bastion host"
#   value       = module.bastion.private_dns
#   sensitive   = true
# }

# output "dynamodb_name" {
#   description = "Name of DynmoDB table"
#   value       = module.loki_s3_bucket.dynamodb_name
#   sensitive   = true
# }

# output "vpc_cidr" {
#   description = "The CIDR block of the VPC"
#   value       = module.vpc.vpc_cidr_block
#   sensitive   = true
# }

# output "eks_cluster_name" {
#   description = "The name of the EKS cluster"
#   value       = module.eks.cluster_name
#   sensitive   = true
# }
