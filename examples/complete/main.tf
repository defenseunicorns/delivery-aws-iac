data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

resource "random_id" "default" {
  byte_length = 2
}

locals {
  vpc_name                   = "${var.name_prefix}-${lower(random_id.default.hex)}"
  cluster_name               = "${var.name_prefix}-${lower(random_id.default.hex)}"
  bastion_name               = "${var.name_prefix}-bastion-${lower(random_id.default.hex)}"
  loki_name_prefix           = "${var.name_prefix}-loki-${lower(random_id.default.hex)}"
  access_logging_name_prefix = "${var.name_prefix}-accesslog-${lower(random_id.default.hex)}"
  kms_key_alias_name_prefix  = "alias/${var.name_prefix}-${lower(random_id.default.hex)}"
  access_log_sqs_queue_name  = "${var.name_prefix}-accesslog-access-${lower(random_id.default.hex)}"

  account = data.aws_caller_identity.current.account_id

  tags = merge(
    var.tags,
    {
      RootTFModule = replace(basename(path.cwd), "_", "-") # tag names based on the directory name
      GithubRepo   = "github.com/defenseunicorns/iac"
    }
  )

  nodegroup_arn = try(module.eks.eks_managed_node_groups.arn, module.eks.self_managed_node_groups.arn, null)

  eks_managed_node_groups = {
    # Managed Node groups with minimum config
    # Default node group - as provided by AWS EKS
    default_node_group = {
      create = var.enable_eks_managed_nodegroups
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false

      disk_size = 50
    }
  }

  self_managed_node_groups = {
    self_mg1 = {
      create          = var.enable_self_managed_nodegroups
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
    }
  }
}

###########################################################
####################### VPC ###############################

module "vpc" {
  # source = "git::https://github.com/defenseunicorns/iac.git//modules/vpc?ref=v<insert tagged version>"
  source = "../../modules/vpc"

  region                = var.region
  name                  = local.vpc_name
  vpc_cidr              = var.vpc_cidr
  secondary_cidr_blocks = var.secondary_cidr_blocks
  azs                   = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets        = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 5, k)]
  private_subnets       = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 5, k + 4)]
  database_subnets      = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 5, k + 8)]
  intra_subnets         = [for k, v in module.vpc.azs : cidrsubnet(element(module.vpc.vpc_secondary_cidr_blocks, 0), 5, k)]
  single_nat_gateway    = true
  enable_nat_gateway    = true

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  instance_tenancy = "default"
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
  region                         = var.region
  access_logs_bucket_name        = aws_s3_bucket.access_log_bucket.id
  session_log_bucket_name_prefix = "${local.bastion_name}-sessionlogs"
  kms_key_arn                    = aws_kms_key.default.arn
  ssh_user                       = var.bastion_ssh_user
  ssh_password                   = var.bastion_ssh_password
  assign_public_ip               = false
  enable_log_to_s3               = true
  enable_log_to_cloudwatch       = true
  vpc_endpoints_enabled          = true
  tenancy                        = var.bastion_tenancy
  zarf_version                   = var.zarf_version
  tags = merge(
    local.tags,
  { Function = "bastion-ssm" })
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
  control_plane_subnet_ids        = module.vpc.private_subnets
  source_security_group_id        = module.bastion.security_group_ids[0]
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  dataplane_wait_duration         = var.dataplane_wait_duration
  cluster_endpoint_private_access = true
  vpc_cni_custom_subnet           = module.vpc.intra_subnets
  aws_admin_usernames             = var.aws_admin_usernames
  cluster_version                 = var.cluster_version
  bastion_role_arn                = module.bastion.bastion_role_arn
  bastion_role_name               = module.bastion.bastion_role_name
  cidr_blocks                     = module.vpc.private_subnets_cidr_blocks
  nodegroup_arn                   = local.nodegroup_arn
  # If using EKS Managed Node Groups, the aws-auth ConfigMap is created by eks itself and terraform can not create it
  create_aws_auth_configmap = var.create_aws_auth_configmap
  manage_aws_auth_configmap = var.manage_aws_auth_configmap

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
    autoscaling_group_tags = merge(
      local.tags,
      {
        "k8s.io/cluster-autoscaler/enabled" : true,
        "k8s.io/cluster-autoscaler/${local.cluster_name}" : "owned"
    })
    metadata_options = {
      #https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#metadata-options
      http_endpoint               = "enabled"
      http_put_response_hop_limit = 2
      http_tokens                 = "optional" # set to "enabled" to enforce IMDSv2, default for upstream terraform-aws-eks module
    }
    tags = {
      subnet_type = "private"
    }
  }

  tags = local.tags

  self_managed_node_groups = local.self_managed_node_groups

  #---------------------------------------------------------------
  #"native" EKS Add-Ons
  #---------------------------------------------------------------

  cluster_addons = var.cluster_addons

  #---------------------------------------------------------------
  # EKS Blueprints - EKS Add-Ons
  #---------------------------------------------------------------

  # AWS EKS EBS CSI Driver
  enable_amazon_eks_aws_ebs_csi_driver = var.enable_amazon_eks_aws_ebs_csi_driver
  amazon_eks_aws_ebs_csi_driver_config = var.amazon_eks_aws_ebs_csi_driver_config

  # AWS EKS EFS CSI Driver
  enable_efs     = var.enable_efs
  reclaim_policy = var.reclaim_policy

  # AWS EKS node termination handler
  enable_aws_node_termination_handler      = var.enable_aws_node_termination_handler
  aws_node_termination_handler_helm_config = var.aws_node_termination_handler_helm_config

  # k8s Metrics Server
  enable_metrics_server      = var.enable_metrics_server
  metrics_server_helm_config = var.metrics_server_helm_config

  # k8s Cluster Autoscaler
  enable_cluster_autoscaler      = var.enable_cluster_autoscaler
  cluster_autoscaler_helm_config = var.cluster_autoscaler_helm_config

  #Calico
  enable_calico      = var.enable_calico
  calico_helm_config = var.calico_helm_config
}
