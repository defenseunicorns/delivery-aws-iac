###########################################################
################## Global Settings ########################

variable "region" {
  description = "The AWS region to deploy into"
  type        = string
}

variable "region2" {
  description = "The AWS region to deploy into"
  type        = string
}

variable "account" {
  description = "The AWS account to deploy into"
  type        = string
}

variable "aws_profile" {
  description = "The AWS profile to use for deployment"
  type        = string
}

variable "aws_admin_usernames" {
  description = "A list of one or more AWS usernames with admin access to KMS and EKS resources"
  type        = list(string)
}

variable "manage_aws_auth_configmap" {
  description = "Determines whether to manage the aws-auth configmap"
  type        = bool
  default     = false
}

variable "create_aws_auth_configmap" {
  description = "Determines whether to create the aws-auth configmap. NOTE - this is only intended for scenarios where the configmap does not exist (i.e. - when using only self-managed node groups). Most users should use `manage_aws_auth_configmap`"
  type        = bool
  default     = false
}

variable "default_tags" {
  description = "A map of default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

###########################################################
#################### VPC Config ###########################

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "The name to use for the VPC"
  type        = string
  default     = "my-vpc"
}

variable "create_database_subnet_group" {
  description = "Whether to create a database subnet group"
  type        = bool
  default     = true
}

variable "create_database_subnet_route_table" {
  description = "Whether to create a database subnet route table"
  type        = bool
  default     = true
}

variable "intra_subnets" {
  description = "A list of intra subnets"
  type        = list(string)
  default     = []
}

###########################################################
#################### EKS Config ###########################

variable "cluster_name" {
  description = "The name to use for the EKS cluster"
  type        = string
  default     = "my-eks"
}

variable "cluster_version" {
  description = "The Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.23"
}

variable "cluster_endpoint_public_access" {
  description = "Whether to enable private access to the EKS cluster"
  type        = bool
  default     = false
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
  default     = false
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
  default     = false
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
  default     = false
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
  default     = false
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
  default     = false
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
  default     = false
}

variable "cluster_autoscaler_helm_config" {
  description = "Cluster Autoscaler Helm Chart config"
  type        = any
  default     = {}
}

###########################################################
################## Bastion Config #########################

variable "bastion_name" {
  description = "The name to use for the bastion"
  type        = string
  default     = "my-bastion"
}

variable "bastion_instance_type" {
  description = "value for the instance type of the EKS worker nodes"
  type        = string
  default     = "m5.xlarge"
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the bastion"
  type        = bool
  default     = false
}

variable "bastion_ami_id" {
  description = "(Optional) The AMI ID to use for the bastion, will query the latest Amazon Linux 2 AMI if not provided"
  type        = string
  default     = ""
}

variable "bastion_ssh_user" {
  description = "The SSH user to use for the bastion"
  type        = string
  default     = "ec2-user"
}

variable "bastion_ssh_password" {
  description = "The SSH password to use for the bastion if SSM authentication is used"
  type        = string
  default     = "my-password"
}

###########################################################
############## Big Bang Dependencies ######################

variable "keycloak_enabled" {
  description = "Whether to enable Keycloak"
  type        = bool
  default     = false
}

#################### Keycloak ###########################

variable "keycloak_db_password" {
  description = "The password to use for the Keycloak database"
  type        = string
  default     = "my-password"
}

variable "kc_db_engine_version" {
  description = "The database engine to use for Keycloak"
  type        = string
}

variable "kc_db_family" {
  description = "The database family to use for Keycloak"
  type        = string
}

variable "kc_db_major_engine_version" {
  description = "The database major engine version to use for Keycloak"
  type        = string
}

variable "kc_db_instance_class" {
  description = "The database instance class to use for Keycloak"
  type        = string
}

variable "kc_db_allocated_storage" {
  description = "The database allocated storage to use for Keycloak"
  type        = number
}

variable "kc_db_max_allocated_storage" {
  description = "The database allocated storage to use for Keycloak"
  type        = number
}

variable "vpc_instance_tenancy" {
  description = "The tenancy of instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "bastion_tenancy" {
  description = "The tenancy of the bastion"
  type        = string
  default     = "default"
}

variable "eks_worker_tenancy" {
  description = "The tenancy of the EKS worker nodes"
  type        = string
  default     = "default"
}

variable "zarf_version" {
  description = "The version of Zarf to use"
  type        = string
  default     = ""
}
