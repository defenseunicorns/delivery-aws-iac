locals {
  name                   = basename(path.cwd)
  availability_zone_name = slice(data.aws_availability_zones.available.names, 0, 3)
  azs                    = slice(data.aws_availability_zones.available.names, 0, 3)

  # var.cluster_name is for Terratest
  cluster_name = coalesce(var.cluster_name, var.name)

  admin_arns = distinct(concat(
    [for admin_user in var.aws_admin_usernames : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:user/${admin_user}"],
    [data.aws_caller_identity.current.arn]
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

  # if using EKS Managed Node Groups you can not also create the aws-auth configmap because eks does it for you - it will already exist when TF tries to create it and you will receive an error.
  # the following logic determines if the aws-auth configmap should be created or not by checking if eks_managed_node_groups would be created based on inputs to the upstream eks module
  # this returns true (will create the configmap) if eks_managed_node_groups is empty or if eks_managed_node_groups is not empty AND all eks_managed_node_groups.*.create values are set to false
  # it returns false (won't create the configmap) when eks_managed_node_groups is not empty AND at least one eks_managed_node_groups.*.create value is set to true OR is not defined
  create_aws_auth_configmap = !(
    # Check if eks_managed_node_groups is not empty
    length(var.eks_managed_node_groups) > 0 && (
      # Check if any EKS managed node group value is set to create or not defined, if not defined, then set to true as null = true in upstream.
      length([for v in values(var.eks_managed_node_groups) : v if try(v.create, true) == true]) > 0 ||
      # Check if all EKS managed node groups have create set to false
      length([for v in values(var.eks_managed_node_groups) : v if try(v.create, true) == false]) < length(var.eks_managed_node_groups)
    )
  )

  cluster_addons = {
    vpc-cni = lookup(var.amazon_eks_vpc_cni, "enable", null) ? {
      before_compute       = lookup(var.amazon_eks_vpc_cni, "before_compute", null)
      most_recent          = lookup(var.amazon_eks_vpc_cni, "most_recent", null)
      configuration_values = jsonencode({ env = (lookup(var.amazon_eks_vpc_cni, "configuration_values", null)) })
      resolve_conflicts    = lookup(var.amazon_eks_vpc_cni, "resolve_conflicts", null)
    } : null
  }
}
