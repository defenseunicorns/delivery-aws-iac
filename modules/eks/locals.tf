locals {
  # var.cluster_name is for Terratest
  cluster_name = coalesce(var.cluster_name, var.name)

  tags = {
    Blueprint  = var.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
  admin_arns = [for admin_user in var.aws_admin_usernames : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:user/${admin_user}"]
  aws_auth_users = [for admin_user in var.aws_admin_usernames : {
    userarn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:user/${admin_user}"
    username = admin_user
    groups   = ["system:masters"]
    }
  ]

  cluster_addons = {
    #if enabled, pass in config vars, else null
    vpc-cni = (
      var.enable_amazon_eks_vpc_cni ? {
        before_compute       = var.amazon_eks_vpc_cni_before_compute
        most_recent          = var.amazon_eks_vpc_cni_most_recent
        configuration_values = jsonencode({ env = var.amazon_eks_vpc_cni_configuration_values })
        resolve_conflict     = var.amazon_eks_vpc_cni_resolve_conflict
      } : null
    )
  }
}
