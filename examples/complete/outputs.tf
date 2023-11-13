# Root module outputs
# Setting all of them sensitive = true to avoid having their details logged to the console in our public CI pipelines

output "bastion_instance_id" {
  description = "The ID of the bastion host"
  value       = try(module.bastion[0].instance_id, null)
  sensitive   = true
}

output "bastion_region" {
  description = "The region that the bastion host was deployed to"
  value       = try(module.bastion[0].region, null)
  sensitive   = true
}

output "bastion_private_dns" {
  description = "The private DNS address of the bastion host"
  value       = try(module.bastion[0].private_dns, null)
  sensitive   = true
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
  sensitive   = true
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
  sensitive   = true
}

output "efs_storageclass_name" {
  description = "The name of the EFS storageclass that was created (if var.enable_amazon_eks_aws_efs_csi_driver was set to true)"
  value       = try(module.eks.efs_storageclass_name, null)
}

output "lambda_password_function_arn" {
  description = "Arn for lambda password function"
  value       = try(module.password_lambda[0].lambda_password_function_arn, null)
}
