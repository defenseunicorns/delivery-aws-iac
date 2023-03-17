data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ami" "amazonlinux2eks" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-*"]
  }

  owners = ["amazon"]
}

data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-v*"]
  }
}

data "aws_ami" "eks_default_bottlerocket" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["bottlerocket-aws-k8s-${var.cluster_version}-x86_64-*"]
  }
}

resource "random_id" "vpc_name" {
  byte_length = 2
  prefix      = var.vpc_name_prefix
}

resource "random_id" "cluster_name" {
  byte_length = 2
  prefix      = var.cluster_name_prefix
}

resource "random_id" "bastion_name" {
  byte_length = 2
  prefix      = var.bastion_name_prefix
}

locals {
  vpc_name         = lower(random_id.vpc_name.hex)
  cluster_name     = lower(random_id.cluster_name.hex)
  bastion_name     = lower(random_id.bastion_name.hex)
  loki_name_prefix = "${lower(random_id.cluster_name.hex)}-loki"

  account = data.aws_caller_identity.current.account_id

  tags = {
    Blueprint  = "${replace(basename(path.cwd), "_", "-")}" # tag names based on the directory name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }

  eks_managed_node_groups = var.enable_eks_managed_nodegroups == false ? tomap({}) : {
    # Managed Node groups with minimum config
    # Default node group - as provided by AWS EKS
    default_node_group = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false

      disk_size = 50

      # Remote access cannot be specified with a launch template
      remote_access = {
        ec2_ssh_key               = module.key_pair.key_pair_name
        source_security_group_ids = [aws_security_group.remote_access.id]
      }
    }

    # Default node group - as provided by AWS EKS using Bottlerocket
    bottlerocket_default = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false

      ami_type = "BOTTLEROCKET_x86_64"
      platform = "bottlerocket"
    }

    # Adds to the AWS provided user data
    bottlerocket_add = {
      ami_type = "BOTTLEROCKET_x86_64"
      platform = "bottlerocket"

      # This will get added to what AWS provides
      bootstrap_extra_args = <<-EOT
        # extra args added
        [settings.kernel]
        lockdown = "integrity"
      EOT
    }

    # Custom AMI, using module provided bootstrap data
    bottlerocket_custom = {
      # Current bottlerocket AMI
      ami_id   = data.aws_ami.eks_default_bottlerocket.image_id
      platform = "bottlerocket"

      # Use module user data template to bootstrap
      enable_bootstrap_user_data = true
      # This will get added to the template
      bootstrap_extra_args = <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default, but can be disabled explicitly.
        [settings.host-containers.admin]
        enabled = false

        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true

        # extra args added
        [settings.kernel]
        lockdown = "integrity"

        [settings.kubernetes.node-labels]
        label1 = "foo"
        label2 = "bar"

        [settings.kubernetes.node-taints]
        dedicated = "experimental:PreferNoSchedule"
        special = "true:NoSchedule"
      EOT
    }

    # Complete
    complete = {
      name            = "complete-eks-mng"
      use_name_prefix = true

      subnet_ids = module.vpc.private_subnets

      min_size     = 1
      max_size     = 7
      desired_size = 1

      ami_id                     = data.aws_ami.eks_default.image_id
      enable_bootstrap_user_data = true

      pre_bootstrap_user_data = <<-EOT
        export FOO=bar
      EOT

      post_bootstrap_user_data = <<-EOT
        echo "you are free little kubelet!"
      EOT

      capacity_type        = "SPOT"
      force_update_version = true
      instance_types       = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
      labels = {
        GithubRepo = "terraform-aws-eks"
        GithubOrg  = "terraform-aws-modules"
      }

      taints = [
        {
          key    = "dedicated"
          value  = "gpuGroup"
          effect = "NO_SCHEDULE"
        }
      ]

      update_config = {
        max_unavailable_percentage = 33 # or set `max_unavailable`
      }

      description = "EKS managed node group example launch template"

      ebs_optimized           = true
      disable_api_termination = false
      enable_monitoring       = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 75
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = "2"
        instance_metadata_tags      = "disabled"
      }

      create_iam_role          = true
      iam_role_name            = "eks-managed-node-group-complete-example"
      iam_role_use_name_prefix = false
      iam_role_description     = "EKS managed node group complete example role"
      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonSSMManagedInstanceCore       = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"

      }

      tags = {
        ExtraTag = "EKS managed node group complete example"
      }
    }
  }

  self_managed_node_groups = var.enable_self_managed_nodegroups == false ? tomap({}) : {
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
}

###########################################################
####################### VPC ###############################

module "vpc" {
  # source = "git::https://github.com/defenseunicorns/iac.git//modules/vpc?ref=v<insert tagged version>"
  source = "../../modules/vpc"

  region             = var.region
  name               = local.vpc_name
  vpc_cidr           = var.vpc_cidr
  azs                = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets     = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 5, k)]
  private_subnets    = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 5, k + 4)]
  database_subnets   = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 5, k + 8)]
  intra_subnets      = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 5, k + 12)]
  single_nat_gateway = true
  enable_nat_gateway = true

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  instance_tenancy = var.vpc_instance_tenancy # dedicated tenancy globally set in VPC does not currently work with EKS
}

###########################################################
##################### Bastion #############################

data "aws_ami" "amazonlinux2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*x86_64-gp2"]
  }

  owners = ["amazon"]
}

module "bastion" {
  # source = "git::https://github.com/defenseunicorns/iac.git//modules/bastion?ref=v<insert tagged version>"
  source = "../../modules/bastion"

  ami_id        = data.aws_ami.amazonlinux2.id
  instance_type = var.bastion_instance_type
  root_volume_config = {
    volume_type = "gp3"
    volume_size = "20"
    encrypted   = true
  }
  name                           = local.bastion_name
  vpc_id                         = module.vpc.vpc_id
  subnet_id                      = module.vpc.private_subnets[0]
  aws_region                     = var.region
  access_log_bucket_name_prefix  = "${local.bastion_name}-accesslogs"
  session_log_bucket_name_prefix = "${local.bastion_name}-sessionlogs"
  ssh_user                       = var.bastion_ssh_user
  ssh_password                   = var.bastion_ssh_password
  assign_public_ip               = false # var.assign_public_ip
  enable_log_to_s3               = true
  enable_log_to_cloudwatch       = true
  vpc_endpoints_enabled          = true
  tenancy                        = var.bastion_tenancy
  zarf_version                   = var.zarf_version
  tags = {
    Function = "bastion-ssm"
  }
}

###########################################################
################### EKS Cluster ###########################
module "eks" {
  # source = "git::https://github.com/defenseunicorns/iac.git//modules/eks?ref=v<insert tagged version>"
  source = "../../modules/eks"

  name                            = local.cluster_name
  aws_region                      = var.region
  aws_account                     = local.account
  vpc_id                          = module.vpc.vpc_id
  private_subnet_ids              = module.vpc.private_subnets
  source_security_group_id        = module.bastion.security_group_ids[0]
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = true
  vpc_cni_custom_subnet           = module.vpc.intra_subnets
  aws_admin_usernames             = var.aws_admin_usernames
  cluster_version                 = var.cluster_version
  bastion_role_arn                = module.bastion.bastion_role_arn
  bastion_role_name               = module.bastion.bastion_role_name

  ######################## EKS Managed Node Group ###################################
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = local.eks_managed_node_groups

  ######################## Self Managed Node Group ###################################
  self_managed_node_group_defaults = {
    instance_type                          = "m5.xlarge"
    update_launch_template_default_version = true
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
    # enable discovery of autoscaling groups by cluster-autoscaler
    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${local.cluster_name}" : "owned"
    }
    metadata_options = {
      #https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#metadata-options
      http_endpoint               = "enabled"
      http_put_response_hop_limit = 2
      http_tokens                 = "optional" # set to "enabled" to enforce IMDSv2, default for upstream terraform-aws-eks module
    }
  }

  self_managed_node_groups = local.self_managed_node_groups

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

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0"

  key_name_prefix    = local.cluster_name
  create_private_key = true

  tags = local.tags
}

resource "aws_security_group" "remote_access" {
  name_prefix = "${local.cluster_name}-remote-access"
  description = "Allow remote SSH access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
