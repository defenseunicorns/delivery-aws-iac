data "aws_partition" "current" {}

locals {
  tags = {
    Blueprint  = replace(basename(path.cwd), "_", "-") # tag names based on the directory name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

data "aws_ami" "amazonlinux2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*x86_64-gp2"]
  }

  owners = ["amazon"]
}

###########################################################
####################### VPC ###############################

module "vpc" {
  # source = "git::https://github.com/defenseunicorns/iac.git//modules/vpc?ref=v<insert tagged version>"
  source = "../../modules/vpc"

  region             = var.region
  name               = var.vpc_name
  vpc_cidr           = var.vpc_cidr
  azs                = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets     = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 5, k)]
  private_subnets    = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 5, k + 4)]
  database_subnets   = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 5, k + 8)]
  intra_subnets      = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 5, k + 12)]
  single_nat_gateway = true
  enable_nat_gateway = true

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }
  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  instance_tenancy = var.vpc_instance_tenancy # dedicated tenancy globally set in VPC does not currently work with EKS
}

###########################################################
##################### Bastion #############################

module "bastion" {
  # source = "git::https://github.com/defenseunicorns/iac.git//modules/bastion?ref=v<insert tagged version>"
  source = "../../modules/bastion"

  ami_id        = coalesce(var.bastion_ami_id, data.aws_ami.amazonlinux2.id) #use var.bastion_ami_id if set, otherwise use the latest Amazon Linux 2 AMI
  instance_type = var.bastion_instance_type
  root_volume_config = {
    volume_type = "gp3"
    volume_size = "20"
    encrypted   = true
  }
  name                     = var.bastion_name
  vpc_id                   = module.vpc.vpc_id
  subnet_id                = module.vpc.private_subnets[0]
  aws_region               = var.region
  access_log_bucket_name   = "${var.bastion_name}-access-logs"
  bucket_name              = "${var.bastion_name}-session-logs"
  ssh_user                 = var.bastion_ssh_user
  ssh_password             = var.bastion_ssh_password
  assign_public_ip         = false # var.assign_public_ip
  enable_log_to_s3         = true
  enable_log_to_cloudwatch = true
  vpc_endpoints_enabled    = true
  tenancy                  = var.bastion_tenancy
  zarf_version             = var.zarf_version
  tags = {
    Function = "bastion-ssm"
  }
}

###########################################################
################### EKS Cluster ###########################
module "eks" {
  # source = "git::https://github.com/defenseunicorns/iac.git//modules/eks?ref=v<insert tagged version>"
  source = "../../modules/eks"

  name                  = var.cluster_name
  aws_region            = var.region
  aws_account           = var.account
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnets
  vpc_cni_custom_subnet = module.vpc.intra_subnets
  # control_plane_subnet_ids              = module.vpc.private_subnets #uses subnet_ids if not set
  source_security_group_id        = module.bastion.security_group_ids[0]
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = true
  aws_admin_usernames             = var.aws_admin_usernames
  cluster_version                 = var.cluster_version
  bastion_role_arn                = module.bastion.bastion_role_arn
  bastion_role_name               = module.bastion.bastion_role_name

  #AWS_AUTH
  manage_aws_auth_configmap = var.manage_aws_auth_configmap
  create_aws_auth_configmap = var.create_aws_auth_configmap

  ###########################################################
  # Self Managed Node Groups

  self_managed_node_group_defaults = {
    instance_type                          = "m5.xlarge"
    update_launch_template_default_version = true
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
    # enable discovery of autoscaling groups by cluster-autoscaler
    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${var.cluster_name}" : "owned"
    }
    metadata_options = {
      #https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#metadata-options
      http_endpoint               = "enabled"
      http_put_response_hop_limit = 2
      http_tokens                 = "optional" # set to "enabled" to enforce IMDSv2, default for upstream terraform-aws-eks module
    }
  }

  self_managed_node_groups = {
    self_mg1 = {
      node_group_name = "self_mg1"
      subnet_ids      = module.vpc.private_subnets

      min_size     = 3
      max_size     = 10
      desired_size = 3

      # ami_id = "" # defaults to latest amazon linux 2 eks ami matching k8s version in the upstream module
      # create_iam_role           = true                                                    # Changing `create_iam_role=false` to bring your own IAM Role
      # iam_role_arn              = module.eks.aws_iam_role_self_managed_ng_arn              # custom IAM role for aws-auth mapping; used when create_iam_role = false
      # iam_instance_profile_name = module.eks.aws_iam_instance_profile_self_managed_ng_name # IAM instance profile name for Launch templates; used when create_iam_role = false
      placement = {
        tenancy = var.eks_worker_tenancy
      }

      metadata_options = false

      pre_bootstrap_userdata = <<-EOT
        yum install -y amazon-ssm-agent
        systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
      EOT

      post_userdata = <<-EOT
        echo "Bootstrap successfully completed! You can further apply config or install to run after bootstrap if needed"
      EOT

      # bootstrap_extra_args used only when you pass custom_ami_id. Allows you to change the Container Runtime for Nodes
      # e.g., bootstrap_extra_args="--use-max-pods false --container-runtime containerd"
      bootstrap_extra_args = "--use-max-pods false"

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 50
            volume_type = "gp3"
          }
        },
        xvdf = {
          device_name = "/dev/xvdf"
          ebs = {
            volume_size = 80
            volume_type = "gp3"
            iops        = 3000
            throughput  = 125
          }
        },
        xvdg = {
          device_name = "/dev/xvdg"
          ebs = {
            volume_size = 100
            volume_type = "gp3"
            iops        = 3000
            throughput  = 125
          }
        }
      }

      instance_type = "m5.xlarge"
      #capacity_type = "" # Optional Use this only for SPOT capacity as  capacity_type = "spot". Only for eks_managed_node_groups

      tags = {
        subnet_type = "private"
      }
    }
  }

  #---------------------------------------------------------------
  #"native" EKS Add-Ons
  #---------------------------------------------------------------

  # VPC CNI
  amazon_eks_vpc_cni = var.amazon_eks_vpc_cni

  #---------------------------------------------------------------
  # EKS Blueprints - EKS Add-Ons
  #---------------------------------------------------------------

  # EKS CoreDNS
  enable_amazon_eks_coredns = var.enable_amazon_eks_coredns
  amazon_eks_coredns_config = var.amazon_eks_coredns_config

  # EKS kube-proxy
  enable_amazon_eks_kube_proxy = var.enable_amazon_eks_kube_proxy
  amazon_eks_kube_proxy_config = var.amazon_eks_kube_proxy_config

  # EKS EBS CSI Driver
  enable_amazon_eks_aws_ebs_csi_driver = var.enable_amazon_eks_aws_ebs_csi_driver
  amazon_eks_aws_ebs_csi_driver_config = var.amazon_eks_aws_ebs_csi_driver_config

  # EKS Metrics Server
  enable_metrics_server      = var.enable_metrics_server
  metrics_server_helm_config = var.metrics_server_helm_config

  # EKS AWS node termination handler
  enable_aws_node_termination_handler      = var.enable_aws_node_termination_handler
  aws_node_termination_handler_helm_config = var.aws_node_termination_handler_helm_config

  # EKS Cluster Autoscaler
  enable_cluster_autoscaler      = var.enable_cluster_autoscaler
  cluster_autoscaler_helm_config = var.cluster_autoscaler_helm_config
}
