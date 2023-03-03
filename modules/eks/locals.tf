locals {
  # var.cluster_name is for Terratest
  cluster_name = coalesce(var.cluster_name, var.name)

  tags = {
    Blueprint  = var.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }

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
