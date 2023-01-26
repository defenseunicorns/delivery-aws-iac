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
  source = "git::https://github.com/defenseunicorns/iac.git//modules/vpc?ref=v0.0.0-alpha.2"

  region   = var.region
  name     = var.vpc_name
  vpc_cidr = var.vpc_cidr
  azs      = ["${var.region}a", "${var.region}b", "${var.region}c"]

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }
  create_database_subnet_group       = true
  create_database_subnet_route_table = true
}

###########################################################
################### EKS Cluster ###########################

module "eks" {
  source = "git::https://github.com/defenseunicorns/iac.git//modules/eks?ref=v0.0.0-alpha.2"

  name                     = var.cluster_name
  vpc_id                   = module.vpc.vpc_id
  private_subnet_ids       = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets
  # cluster_endpoint_public_access        = true
  # cluster_endpoint_private_access       = false
  aws_region                            = var.region
  aws_account                           = var.account
  cluster_kms_key_additional_admin_arns = ["arn:${data.aws_partition.current.partition}:iam::${var.account}:user/${var.aws_admin_1_username}", "arn:${data.aws_partition.current.partition}:iam::${var.account}:user/${var.aws_admin_2_username}"]
  eks_k8s_version                       = var.eks_k8s_version
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
  source_security_group_id = module.bastion.security_group_ids[0]
}

###########################################################
################# Enable EKS Sops #########################

module "flux_sops" {
  source = "git::https://github.com/defenseunicorns/iac.git//modules/sops?ref=v0.0.0-alpha.2"

  region                     = var.region
  cluster_name               = module.eks.eks_cluster_id
  vpc_id                     = module.vpc.vpc_id
  policy_name_prefix         = "${module.eks.eks_cluster_id}-flux-sops"
  kms_key_alias              = "${module.eks.eks_cluster_id}-flux-sops"
  kubernetes_service_account = "flux-system-sops-sa"
  kubernetes_namespace       = "flux-system"
  irsa_sops_iam_role_name    = "${module.eks.eks_cluster_id}-flux-system-sa-role"
  eks_oidc_provider_arn      = module.eks.eks_oidc_provider_arn
  tags                       = local.tags
}

###########################################################
##################### Bastion #############################

module "bastion" {
  source = "git::https://github.com/defenseunicorns/iac.git//modules/bastion?ref=v0.0.0-alpha.2"

  ami_id                 = var.bastion_ami_id
  name                   = var.bastion_name
  vpc_id                 = module.vpc.vpc_id
  subnet_id              = module.vpc.private_subnets[0]
  aws_region             = var.region
  access_log_bucket_name = "${var.bastion_name}-access-logs"
  bucket_name            = "${var.bastion_name}-session-logs"
  ssh_user               = var.ssh_user
  ssh_password           = var.bastion_ssh_password
  assign_public_ip       = false # var.assign_public_ip
  # cluster_sops_policy_arn = module.flux_sops.sops_policy_arn
  enable_log_to_s3         = true
  enable_log_to_cloudwatch = true
  vpc_endpoints_enabled    = true
  tags = {
    Function = "bastion-ssm"
  }
}

###########################################################
############## Big Bang Core Dependencies #################
###########################################################


###########################################################
################## Loki S3 Bucket #########################

module "loki_s3_bucket" {
  # source = "git::https://github.com/defenseunicorns/iac.git//modules/s3-irsa?ref=v0.0.0-alpha.2"
    source  = "../../modules/s3-irsa"
  region                     = var.region
  cluster_name               = module.eks.eks_cluster_id
  policy_name_prefix         = "loki-s3-policy"
  bucket_prefix              = "loki-s3"
  kms_key_alias              = "loki-s3"
  kubernetes_service_account = "logging-loki-s3-sa"
  kubernetes_namespace       = "logging"
  irsa_iam_role_name         = "${module.eks.eks_cluster_id}-logging-loki-sa-role"
  eks_oidc_provider_arn      = module.eks.eks_oidc_provider_arn
  tags                       = local.tags
  dynamodb_enabled           = true
}
