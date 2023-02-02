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

variable "aws_admin_1_username" {
  description = "The AWS admin username to use for deployment"
  type        = string
}

variable "aws_admin_2_username" {
  description = "The AWS admin username to use for deployment"
  type        = string
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

###########################################################
#################### EKS Config ###########################

variable "cluster_name" {
  description = "The name to use for the EKS cluster"
  type        = string
  default     = "my-eks"
}

variable "eks_k8s_version" {
  description = "The Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.23"
}

variable "node_group_name" {
  description = "The name of your node groups"
  type        = string
  default     = "self_ng"
}

variable "launch_template_os" {
  description = "The name of your launch template os"
  default     = "amazonlinux2eks"

}

variable "create_launch_template" {
  description = "Do you want to create a launch template?"
  type        = bool
  default     = true
}

variable "format_mount_nvme_disk" {
  description = "Format the NVMe disk during the instance launch"
  type        = bool
  default     = true
}

variable "custom_ami_id" {
  description = "The ami id of your custom ami"
  default     = ""
}

variable "create_iam_role" {
  description = "Do you want to create an iam role"
  type        = bool
  default     = false
}

variable "public_ip" {
  description = "Associate a public IP address with the instance"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring for the instance"
  type        = bool
  default     = false
}

variable "enable_metadata_options" {
  description = "Enable metadata options for the instance"
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "Instance type for the instances in the cluster"
  type        = string
  default     = "m5.xlarge"
}

variable "desired_size" {
  description = "Desired size of the cluster"
  type        = number
  default     = 3
}

variable "max_size" {
  description = "Maximum size of the cluster"
  type        = number
  default     = 10
}
variable "min_size" {
  description = "Minimum size of the cluster"
  type        = number
  default     = 3
}

variable "cni_add_on" {
  description = "enables eks cni add-on"
  type        = bool
  default     = true
}

variable "coredns" {
  description = "enables eks coredns"
  type        = bool
  default     = true
}

variable "kube_proxy" {
  description = "enables eks kube proxy"
  type        = bool
  default     = true
}

variable "metric_server" {
  description = "enables k8 metrics server "
  type        = bool
  default     = true
}

variable "ebs_csi_add_on" {
  description = "enables the ebs csi driver add-on"
  type        = bool
  default     = true
}

variable "aws_node_termination_handler" {
  description = "enables k8 node termination handler"
  type        = bool
  default     = true
}

variable "cluster_autoscaler" {
  description = "enables the cluster autoscaler"
  type        = bool
  default     = true
}

###########################################################
################## Bastion Config #########################

variable "bastion_name" {
  description = "The name to use for the bastion"
  type        = string
  default     = "my-bastion"
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the bastion"
  type        = bool
  default     = false
}

variable "bastion_ami_id" {
  description = "The AMI ID to use for the bastion"
  type        = string
  default     = "ami-000d4884381edb14c"
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
