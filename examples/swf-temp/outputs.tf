# Root module outputs
# Setting all of them sensitive = true to avoid having their details logged to the console in our public CI pipelines


output "bastion_instance_id" {
  description = "The ID of the bastion host"
  value       = module.bastion.instance_id
}

output "bastion_region" {
  description = "The region that the bastion host was deployed to"
  value       = module.bastion.region
}

output "bastion_private_dns" {
  description = "The private DNS address of the bastion host"
  value       = module.bastion.private_dns
  sensitive   = true
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "efs_storageclass_name" {
  description = "The name of the EFS storageclass that was created (if var.enable_efs was set to true)"
  value       = try(module.eks.efs_storageclass_name, null)
}
