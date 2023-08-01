data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

resource "random_id" "default" {
  byte_length = 2
}

locals {
  vpc_name                   = "${var.name_prefix}-${lower(random_id.default.hex)}"
  cluster_name               = "${var.name_prefix}-${lower(random_id.default.hex)}"
  bastion_name               = "${var.name_prefix}-bastion-${lower(random_id.default.hex)}"
  access_logging_name_prefix = "${var.name_prefix}-accesslog-${lower(random_id.default.hex)}"
  kms_key_alias_name_prefix  = "alias/${var.name_prefix}-${lower(random_id.default.hex)}"
  access_log_sqs_queue_name  = "${var.name_prefix}-accesslog-access-${lower(random_id.default.hex)}"
  tags = merge(
    var.tags,
    {
      RootTFModule = replace(basename(path.cwd), "_", "-") # tag names based on the directory name
      GithubRepo   = "github.com/defenseunicorns/delivery-aws-iac"
    }
  )

  self_managed_node_group_defaults = {
    iam_role_permissions_boundary          = var.iam_role_permissions_boundary
    instance_type                          = "c4.8xlarge" # should be compatible with dedicated tenancy in GovCloud region https://aws.amazon.com/ec2/pricing/dedicated-instances/#Dedicated_On-Demand_instances
    update_launch_template_default_version = true

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

    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore      = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore",
      AmazonElasticFileSystemFullAccess = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonElasticFileSystemFullAccess"
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
      subnet_type = "private",
      cluster     = local.cluster_name
    }
  }

  swf_self_mg_node_group = {
    swf_ng = {
      subnet_ids   = module.vpc.private_subnets
      min_size     = 3
      max_size     = 5
      desired_size = 3

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 200
            volume_type = "gp3"
          }
        }
      }
    }
  }

  self_managed_node_groups = local.swf_self_mg_node_group
}

###########################################################
####################### VPC ###############################

module "vpc" {
  source = "git::https://github.com/defenseunicorns/terraform-aws-uds-vpc.git?ref=v0.0.2"

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
  create_database_subnet_group = true

  instance_tenancy                  = "default"
  vpc_flow_log_permissions_boundary = var.iam_role_permissions_boundary

  tags = local.tags
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
  source = "git::https://github.com/defenseunicorns/terraform-aws-uds-bastion.git?ref=v0.0.2-alpha"

  enable_bastion_terraform_permissions = true

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
  tenancy                        = var.bastion_tenancy
  zarf_version                   = var.zarf_version
  permissions_boundary           = var.iam_role_permissions_boundary
  tags = merge(
    local.tags,
    { Function = "bastion-ssm" }
  )
}

###########################################################
################### EKS Cluster ###########################
module "eks" {
  source = "git::https://github.com/defenseunicorns/terraform-aws-uds-eks.git?ref=v0.0.3"

  name                            = local.cluster_name
  aws_region                      = var.region
  vpc_id                          = module.vpc.vpc_id
  private_subnet_ids              = module.vpc.private_subnets
  control_plane_subnet_ids        = module.vpc.private_subnets
  iam_role_permissions_boundary   = var.iam_role_permissions_boundary
  source_security_group_id        = module.bastion.security_group_ids[0]
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = true
  vpc_cni_custom_subnet           = module.vpc.intra_subnets
  aws_admin_usernames             = var.aws_admin_usernames
  cluster_version                 = var.cluster_version
  bastion_role_arn                = module.bastion.bastion_role_arn
  bastion_role_name               = module.bastion.bastion_role_name
  cidr_blocks                     = module.vpc.private_subnets_cidr_blocks

  # If using EKS Managed Node Groups, the aws-auth ConfigMap is created by eks itself and terraform can not create it
  create_aws_auth_configmap = var.create_aws_auth_configmap
  manage_aws_auth_configmap = var.manage_aws_auth_configmap

  ######################## Self Managed Node Group ###################################
  self_managed_node_group_defaults = local.self_managed_node_group_defaults
  self_managed_node_groups         = local.self_managed_node_groups

  tags = local.tags



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
  enable_gp3_default_storage_class     = var.enable_gp3_default_storage_class
  storageclass_reclaim_policy          = var.storageclass_reclaim_policy

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

############################################################################
##################### Lambda Password Rotation #############################

module "password_lambda" {
  source                          = "../../modules/lambda"
  enable_password_rotation_lambda = var.enable_password_rotation_lambda
  region                          = var.region
  random_id                       = lower(random_id.default.hex)
  name_prefix                     = var.name_prefix
  users                           = var.users
  # Add any additional instances you want the function to run against here
  instance_ids                    = [module.bastion.instance_id]
  cron_schedule_password_rotation = var.cron_schedule_password_rotation
}
