output "aws_eks" {
  #https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/outputs.tf
  description = "all EKS cluster outputs, just for debugging"
  value       = module.aws_eks
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.aws_eks.cluster_name
}

output "managed_nodegroups" {
  description = "EKS managed node groups"
  value       = module.aws_eks.eks_managed_node_groups
}

#you'd need to build some logic around extracting these outputs around module.eks_managed_node_groups which passes all outputs from the child module
# output "eks_managed_nodegroup_ids" {
#   description = "EKS managed node group ids"
#   value       = module.aws_eks.node_group_id
# }

# output "eks_managed_nodegroup_arns" {
#   description = "EKS managed node group arns"
#   value       = module.aws_eks.managed_node_group_arn
# }

# output "eks_managed_nodegroup_role_name" {
#   description = "EKS managed node group role name"
#   value       = module.aws_eks.managed_node_group_iam_role_names
# }

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

# output "aws_iam_role_self_managed_ng_arn" {
#   description = "AWS IAM role self managed node group ARN"
#   value       = try(aws_iam_role.self_managed_ng[0].arn, null)
# }

# output "aws_iam_instance_profile_self_managed_ng_name" {
#   description = "AWS IAM instance profile self managed node group name"
#   value       = try(aws_iam_instance_profile.self_managed_ng[0].name, null)
# }

# output "aws_iam_role_managed_ng_arn" {
#   description = "AWS IAM role managed node group ARN"
#   value       = try(aws_iam_role.managed_ng[0].arn, null)
# }

# output "aws_iam_instance_profile_managed_ng_name" {
#   description = "AWS IAM instance profile managed node group name"
#   value       = try(aws_iam_instance_profile.managed_ng[0].name, null)
# }
