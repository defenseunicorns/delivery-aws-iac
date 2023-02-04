data "aws_partition" "current" {}

locals {
  tags = {
    Blueprint  = "${replace(basename(path.cwd), "_", "-")}" # tag names based on the directory name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

###########################################################
####################### VPC ###############################

module "vpc" {
  # source = "git::https://github.com/defenseunicorns/iac.git//modules/vpc?ref=v<insert tagged version>"
  source = "../../modules/vpc"

  region           = var.region
  name             = var.vpc_name
  vpc_cidr         = var.vpc_cidr
  azs              = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets   = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 8, k)]
  private_subnets  = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 8, k + 10)]
  database_subnets = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 8, k + 20)]

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

  ami_id                   = var.bastion_ami_id
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
  tags = {
    Function = "bastion-ssm"
  }
}

###########################################################
################### EKS Cluster ###########################

module "eks" {
  # source = "git::https://github.com/defenseunicorns/iac.git//modules/eks?ref=v<insert tagged version>"
  source = "../../modules/eks"

  name                     = var.cluster_name
  aws_region               = var.region
  aws_account              = var.account
  vpc_id                   = module.vpc.vpc_id
  private_subnet_ids       = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets
  source_security_group_id = module.bastion.security_group_ids[0]
  tenancy                  = var.eks_worker_tenancy
  # cluster_endpoint_public_access        = true
  # cluster_endpoint_private_access       = false
  cluster_kms_key_additional_admin_arns = ["arn:${data.aws_partition.current.partition}:iam::${var.account}:user/${var.aws_admin_1_username}", "arn:${data.aws_partition.current.partition}:iam::${var.account}:user/${var.aws_admin_2_username}"]
  eks_k8s_version                       = var.eks_k8s_version
  bastion_role_arn                      = module.bastion.bastion_role_arn
  bastion_role_name                     = module.bastion.bastion_role_name
  aws_auth_eks_map_users = [
    {
      userarn  = "arn:${data.aws_partition.current.partition}:iam::${var.account}:user/${var.aws_admin_1_username}"
      username = "${var.aws_admin_1_username}"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:${data.aws_partition.current.partition}:iam::${var.account}:user/${var.aws_admin_2_username}"
      username = "${var.aws_admin_2_username}"
      groups   = ["system:masters"]
    }
  ]
}
