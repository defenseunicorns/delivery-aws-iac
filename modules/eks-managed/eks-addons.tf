#---------------------------------------------------------------
# EKS Add-Ons
#---------------------------------------------------------------

module "eks_blueprints_kubernetes_addons" {
  # pending approval of [PR](https://github.com/aws-ia/terraform-aws-eks-blueprints/issues/1387)
  source     = "git::https://github.com/ntwkninja/terraform-aws-eks-blueprints.git//modules/kubernetes-addons?ref=v4.21.1"
  depends_on = [module.eks_blueprints]

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version

  # EKS Managed Add-ons
  enable_amazon_eks_vpc_cni            = var.enable_eks_vpc_cni
  enable_amazon_eks_coredns            = var.enable_eks_coredns
  enable_amazon_eks_kube_proxy         = var.enable_eks_kube_proxy
  enable_amazon_eks_aws_ebs_csi_driver = var.enable_eks_ebs_csi_driver

  #K8s Add-ons
  enable_metrics_server = var.enable_eks_metrics_server


  enable_cluster_autoscaler      = var.enable_eks_cluster_autoscaler
  cluster_autoscaler_helm_config = var.cluster_autoscaler_helm_config
}
