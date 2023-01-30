# #---------------------------------------------------------------
# # EKS Add-Ons
# #---------------------------------------------------------------

# module "eks_blueprints_kubernetes_addons" {
#   source = "git::https://github.com/ntwkninja/terraform-aws-eks-blueprints.git//modules/kubernetes-addons"
#   depends_on = [module.eks_blueprints]

#   eks_cluster_id           = module.eks_blueprints.eks_cluster_id
#   eks_cluster_endpoint     = module.eks_blueprints.eks_cluster_endpoint
#   eks_oidc_provider        = module.eks_blueprints.oidc_provider
#   eks_cluster_version      = module.eks_blueprints.eks_cluster_version
#   auto_scaling_group_names = module.eks_blueprints.self_managed_node_group_autoscaling_groups

#   # EKS Managed Add-ons
#   enable_amazon_eks_vpc_cni            = true
#   enable_amazon_eks_coredns            = true
#   enable_amazon_eks_kube_proxy         = true
#   enable_amazon_eks_aws_ebs_csi_driver = true

#   #K8s Add-ons
#   enable_metrics_server               = true
#   enable_aws_node_termination_handler = true

#   enable_cluster_autoscaler = true
#   cluster_autoscaler_helm_config = {
#     set = [
#       {
#         name  = "extraArgs.expander"
#         value = "priority"
#       },
#       {
#         name  = "expanderPriorities"
#         value = <<-EOT
#                   100:
#                     - .*-spot-2vcpu-8mem.*
#                   90:
#                     - .*-spot-4vcpu-16mem.*
#                   10:
#                     - .*
#                 EOT
#       }
#     ]
#   }
# }
