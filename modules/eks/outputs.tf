output "aws_eks" {
  #https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/outputs.tf
  description = "all EKS cluster outputs, just for debugging"
  value       = module.aws_eks
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.aws_eks.cluster_name
}

output "cluster_status" {
  description = "status of the EKS cluster"
  value       = module.aws_eks.cluster_status
}

output "managed_nodegroups" {
  description = "EKS managed node groups"
  value       = module.aws_eks.eks_managed_node_groups
}

# Region used for Terratest
output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  value       = module.aws_eks.oidc_provider
}

output "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = module.aws_eks.oidc_provider_arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.aws_eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.aws_eks.cluster_certificate_authority_data
}
