#---------------------------------------------------------------
# EKS Add-Ons
#---------------------------------------------------------------

module "eks_blueprints_kubernetes_addons" {
  source     = "git::https://github.com/aws-ia/terraform-aws-eks-blueprints.git//modules/kubernetes-addons?ref=v4.21.0"
  depends_on = [module.eks_blueprints]

  eks_cluster_id           = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint     = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider        = module.eks_blueprints.oidc_provider
  eks_cluster_version      = module.eks_blueprints.eks_cluster_version
  auto_scaling_group_names = module.eks_blueprints.self_managed_node_group_autoscaling_groups

  # EKS Managed Add-ons
  enable_amazon_eks_vpc_cni            = var.cni_add_on
  enable_amazon_eks_coredns            = var.coredns
  enable_amazon_eks_kube_proxy         = var.kube_proxy
  enable_amazon_eks_aws_ebs_csi_driver = var.ebs_csi_add_on

  #K8s Add-ons
  enable_metrics_server               = var.metric_server
  enable_aws_node_termination_handler = var.aws_node_termination_handler

  enable_cluster_autoscaler = var.cluster_autoscaler
  cluster_autoscaler_helm_config = {
    set = [
      {
        name  = "extraArgs.expander"
        value = "priority"
      },
      {
        name  = "expanderPriorities"
        value = <<-EOT
                  100:
                    - .*-spot-2vcpu-8mem.*
                  90:
                    - .*-spot-4vcpu-16mem.*
                  10:
                    - .*
                EOT
      }
    ]
  }
}
