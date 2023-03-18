locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # var.cluster_name is for Terratest
  cluster_name = coalesce(var.cluster_name, var.name)

  tags = {
    Blueprint  = var.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
  admin_arns = distinct(concat(
    [for admin_user in var.aws_admin_usernames : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:user/${admin_user}"],
    data.aws_caller_identity.current.arn
  ))
  aws_auth_users = distinct(concat([for admin_user in var.aws_admin_usernames : {
    userarn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:user/${admin_user}"
    username = admin_user
    groups   = ["system:masters"]
    }],
    [{
      userarn  = data.aws_caller_identity.current.arn
      username = split("/", data.aws_caller_identity.current.arn)[1]
      groups   = ["system:masters"]
    }]
  ))

  cluster_addons = {
    vpc-cni = lookup(var.amazon_eks_vpc_cni, "enabled", false) ? {
      before_compute       = lookup(var.amazon_eks_vpc_cni, "before_compute", null)
      most_recent          = lookup(var.amazon_eks_vpc_cni, "most_recent", null)
      configuration_values = jsonencode({ env = (lookup(var.amazon_eks_vpc_cni, "configuration_values", null)) })
      resolve_conflicts    = lookup(var.amazon_eks_vpc_cni, "resolve_conflicts", null)
    } : null
  }
}
