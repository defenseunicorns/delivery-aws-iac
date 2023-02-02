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

variable "node_group_name" {
  description = "The name of your node groups"
  type        = string
  default     = "self_mg"
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

variable "custom_ami_id" {
  description = "The ami id of your custom ami"
  default     = ""
}

variable "create_iam_role" {
  description = "Do you want to create an iam role"
  type        = bool
  default     = false
}

variable "format_mount_nvme_disk" {
  description = "Format the NVMe disk during the instance launch"
  type        = bool
  default     = true
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

variable "pre_userdata" {
  type    = string
  default = <<-EOT
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
  EOT
}

variable "bootstrap_extra_args" {
  description = "Additional bootstrap arguments for the instance"
  type        = string
  default     = "--use-max-pods false"
}

variable "block_device_mappings" {
  description = "List of block device mappings for the instance"
  type        = list(map(string))
  default = [
    {
      "device_name" : "/dev/xvda",
      "volume_type" : "gp3",
      "volume_size" : 50
    },
    {
      "device_name" : "/dev/xvdf",
      "volume_type" : "gp3",
      "volume_size" : 80,
      "iops" : 3000,
      "throughput" : 125
    },
    {
      "device_name" : "/dev/xvdg",
      "volume_type" : "gp3",
      "volume_size" : 100,
      "iops" : 3000,
      "throughput" : 125
    }
  ]
}

variable "instance_type" {
  description = "Instance type for the instances in the cluster"
  type        = string
  default     = ""
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
