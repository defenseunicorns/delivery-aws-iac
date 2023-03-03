# tflint-ignore: terraform_unused_declarations
variable "cluster_name" {
  description = "Name of cluster - used by Terratest for e2e test automation"
  type        = string
  default     = ""
}

variable "eks_k8s_version" {
  description = "Kubernetes version to use for EKS cluster"
  type        = string
  default     = "1.23"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
  default     = []
}

variable "aws_region" {
  type    = string
  default = ""
}

variable "aws_account" {
  type    = string
  default = ""
}

variable "name" {
  type    = string
  default = ""
}

variable "aws_auth_eks_map_users" {
  description = "List of map of users to add to aws-auth configmap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "cluster_kms_key_additional_admin_arns" {
  description = "List of ARNs of additional users to add to KMS key policy"
  type        = list(string)
  default     = []
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to the cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the cluster endpoint"
  type        = bool
  default     = false
}

variable "control_plane_subnet_ids" {
  description = "Subnet IDs for control plane"
  type        = list(string)
  default     = []
}

variable "source_security_group_id" {
  description = "List of additional rules to add to cluster security group"
  type        = string
  default     = ""
}

variable "bastion_role_arn" {
  description = "ARN of role authorized kubectl access"
  type        = string
  default     = ""
}

variable "bastion_role_name" {
  description = "Name of role authorized kubectl access"
  type        = string
  default     = ""
}

variable "tenancy" {
  description = "Tenancy of the cluster"
  type        = string
  default     = "dedicated"
}

#-------------------------------
# Node Groups
#-------------------------------

variable "enable_managed_nodegroups" {
  description = "Enable managed node groups. If false, self managed node groups will be used."
  type        = bool
}

variable "managed_node_groups" {
  description = "Managed node groups configuration"
  type        = any
  default     = {}
}

variable "self_managed_node_groups" {
  description = "Self-managed node groups configuration"
  type        = any
  default     = {}
}

###########################################################
################## EKS Addons Config ######################

#----------------AWS EKS VPC CNI-------------------------
variable "enable_amazon_eks_vpc_cni" {
  description = "HANDLED by EKS module, not blueprints: Enable VPC CNI add-on"
  type        = bool
  default     = true
}

variable "amazon_eks_vpc_cni_before_compute" {
  description = "HANDLED by EKS module, not blueprints: Deploy VPC CNI add-on before compute nodes"
  type        = bool
  default     = true
}

variable "amazon_eks_vpc_cni_most_recent" {
  description = "HANDLED by EKS module, not blueprints: Deploy most recent VPC CNI add-on"
  type        = bool
  default     = true
}

variable "amazon_eks_vpc_cni_resolve_conflict" {
  description = "HANDLED by EKS module, not blueprints: Conflict resolution strategy of VPC CNI add-on deployment via eks module"
  type        = string
  default     = "OVERWRITE"
}

variable "amazon_eks_vpc_cni_configuration_values" {
  description = "HANDLED by EKS module, not blueprints: ConfigMap of Amazon EKS VPC CNI add-on"
  type        = any
  default = {
    # Reference https://aws.github.io/aws-eks-best-practices/reliability/docs/networkmanagement/#cni-custom-networking
    AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
    ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"

    # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
    ENABLE_PREFIX_DELEGATION = "true"
    WARM_PREFIX_TARGET       = "1"
  }
}

#----------------AWS CoreDNS-------------------------
variable "enable_amazon_eks_coredns" {
  description = "Enable Amazon EKS CoreDNS add-on"
  type        = bool
  default     = true
}

variable "amazon_eks_coredns_config" {
  description = "Configuration for Amazon CoreDNS EKS add-on"
  type        = any
  default     = {}
}

#----------------AWS Kube Proxy-------------------------
variable "enable_amazon_eks_kube_proxy" {
  description = "Enable Kube Proxy add-on"
  type        = bool
  default     = true
}

variable "amazon_eks_kube_proxy_config" {
  description = "ConfigMap for Amazon EKS Kube-Proxy add-on"
  type        = any
  default     = {}
}

#----------------AWS EBS CSI Driver-------------------------
variable "enable_amazon_eks_aws_ebs_csi_driver" {
  description = "Enable EKS Managed AWS EBS CSI Driver add-on; enable_amazon_eks_aws_ebs_csi_driver and enable_self_managed_aws_ebs_csi_driver are mutually exclusive"
  type        = bool
  default     = true
}

variable "amazon_eks_aws_ebs_csi_driver_config" {
  description = "configMap for AWS EBS CSI Driver add-on"
  type        = any
  default     = {}
}

#----------------Metrics Server-------------------------
variable "enable_metrics_server" {
  description = "Enable metrics server add-on"
  type        = bool
  default     = true
}

variable "metrics_server_helm_config" {
  description = "Metrics Server Helm Chart config"
  type        = any
  default     = {}
}

#----------------AWS Node Termination Handler-------------------------
variable "enable_aws_node_termination_handler" {
  description = "Enable AWS Node Termination Handler add-on"
  type        = bool
  default     = true
}

variable "aws_node_termination_handler_helm_config" {
  description = "AWS Node Termination Handler Helm Chart config"
  type        = any
  default     = {}
}

#----------------Cluster Autoscaler-------------------------
variable "enable_cluster_autoscaler" {
  description = "Enable Cluster autoscaler add-on"
  type        = bool
  default     = true
}

variable "cluster_autoscaler_helm_config" {
  description = "Cluster Autoscaler Helm Chart config"
  type        = any
  default = {
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
