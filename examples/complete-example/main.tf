###########################################################
####################### VPC ###############################

module "vpc" {
  source = "../../modules/vpc"

  region   = local.region
  name     = local.vpc_name
  vpc_cidr = local.vpc_cidr
  azs      = local.azs

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
  database_subnets = local.database_subnets

  create_database_subnet_group       = local.create_database_subnet_group
  create_database_subnet_route_table = local.create_database_subnet_route_table

}

module "ssm" {
  source                    = "bridgecrewio/session-manager/aws"
  version                   = "0.4.2"
  bucket_name               = "my-session-logs"
  access_log_bucket_name    = "my-session-access-logs"
  vpc_id                    = module.vpc.vpc_id
  tags                      = {
                                Function = "ssm"
                              }
  enable_log_to_s3          = true
  enable_log_to_cloudwatch  = true
}

###########################################################
################### EKS Cluster ###########################

module "eks" {
  source = "git::https://github.com/defenseunicorns/iac.git//modules/eks?ref=v0.0.0-alpha.0"

  name                                  = local.cluster_name
  vpc_id                                = module.vpc.vpc_id
  private_subnet_ids                    = module.vpc.private_subnets
  aws_region                            = local.region
  aws_account                           = local.account
  aws_auth_eks_map_users                = local.aws_auth_eks_map_users
  cluster_kms_key_additional_admin_arns = local.cluster_key_admin_arns
  eks_k8s_version                       = local.eks_k8s_version
}

###########################################################
################# Enable EKS Sops #########################

module "flux_sops" {
  source = "git::https://github.com/defenseunicorns/iac.git//modules/sops?ref=v0.0.0-alpha.0"

  region                     = local.region
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
  source = "../../modules/bastion"

  ami_id                  = local.bastion_ami_id
  name                    = local.bastion_name
  vpc_id                  = module.vpc.vpc_id
  subnet_id               = module.vpc.public_subnets[0]
  aws_region              = local.region
  ssh_public_key_names    = local.ssh_public_key_names
  allowed_public_ips      = local.allowed_public_ips
  ssh_user                = local.ssh_user
  assign_public_ip        = local.assign_public_ip
  # cluster_sops_policy_arn = module.flux_sops.sops_policy_arn
  ssmkey_arn              = module.ssm.kms_key_arn
}

###########################################################
############## Big Bang Core Dependencies #################
###########################################################


###########################################################
################## Loki S3 Bucket #########################

module "loki_s3_bucket" {
  source = "git::https://github.com/defenseunicorns/iac.git//modules/s3-irsa?ref=v0.0.0-alpha.0"

  region                     = local.region
  cluster_name               = module.eks.eks_cluster_id
  policy_name_prefix         = "loki-s3-policy"
  bucket_prefix              = "loki-s3"
  kms_key_alias              = "loki-s3"
  kubernetes_service_account = "logging-loki-s3-sa"
  kubernetes_namespace       = "logging"
  irsa_iam_role_name         = "${module.eks.eks_cluster_id}-logging-loki-sa-role"
  eks_oidc_provider_arn      = module.eks.eks_oidc_provider_arn
  tags                       = local.tags
}
