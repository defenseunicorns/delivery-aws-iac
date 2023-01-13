locals {

  ###########################################################
  ################## Global Settings ########################

  region                = "us-east-2"     # target AWS region
  region2               = "us-east-1"     # RDS backup target AWS region
  account               = "8675309"       # target AWS account
  aws_profile           = "something-dev" # local AWS profile to be used for deployment
  aws_admin_1_username  = "bob"           # enables eks access
  aws_admin_2_username  = "jane"          # enables eks access

  tags = {
    Blueprint  = "${replace(basename(path.cwd), "_", "-")}" # tag names based on the directory name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }

  ###########################################################
  #################### VPC Config ###########################

  azs              = ["${local.region}a", "${local.region}b", "${local.region}c"]
  vpc_cidr         = "10.10.0.0/16"
  vpc_name         = "my-vpc"
  database_subnets = ["10.10.17.0/24", "10.10.18.0/24", "10.10.19.0/24"]

  create_database_subnet_group       = true
  create_database_subnet_route_table = true


  ###########################################################
  #################### EKS Config ###########################

  cluster_name           = "my-eks"
  eks_k8s_version        = "1.23"
  cluster_key_admin_arns = ["arn:aws:iam::${local.account}:user/${local.aws_admin_1_username}", "arn:aws:iam::${local.account}:user/${local.aws_admin_2_username}"] # list of admin's AWS account arn to allow control of KMS keys

  # list of admin's AWS account/group info to allow access to EKS cluster // can be moved into iac/modules/eks
  aws_auth_eks_map_users = [
    {
      userarn  = "arn:aws:iam::${local.account}:user/${local.aws_admin_1_username}"
      username = "${local.aws_admin_1_username}"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${local.account}:user/${local.aws_admin_2_username}"
      username = "${local.aws_admin_2_username}"
      groups   = ["system:masters"]
    }
  ]

  ###########################################################
  ################## Bastion Config #########################

  bastion_name     = "my-bastion"
  bastion_ami_id   = "ami-000d4884381edb14c"
  ssh_user         = "ec2-user" # local user in bastion used to ssh

  ###########################################################
  ############## Big Bang Dependencies ######################

  keycloak_enabled = true
  # other_addon_enabled = true


  #################### Keycloak ###########################
  #checkov:skip=CKV_SECRET_6: Example password only
  keycloak_db_password        = "my-password"
  kc_db_engine_version        = "14.1"
  kc_db_family                = "postgres14" # DB parameter group
  kc_db_major_engine_version  = "14"         # DB option group
  kc_db_allocated_storage     = var.kc_db_allocated_storage
  kc_db_max_allocated_storage = var.kc_db_max_allocated_storage
  # kc_db_allocated_storage     = 20
  # kc_db_max_allocated_storage = 100
  kc_db_instance_class        = "db.t4g.large"
}
