locals {

###########################################################
################## Global Settings ########################

  region                      = "###ZARF_VAR_REGION###"  # target AWS region
  region2                     = "###ZARF_VAR_REGION2###"  # RDS backup target AWS region
  account                     = "###ZARF_VAR_AWS_ACCOUNT###"  # target AWS account
  aws_profile                 = "###ZARF_VAR_AWS_PROFILE###"  # local AWS profile to be used for deployment
  aws_admin_1_username = "###ZARF_VAR_AWS_ADMIN_1_USERNAME###" # enables eks access
  aws_admin_2_username = "###ZARF_VAR_AWS_ADMIN_2_USERNAME###" # enables eks access


  tags = {
    Blueprint                 = "${replace(basename(path.cwd), "_", "-")}"  # tag names based on the directory name
    GithubRepo                = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
  
###########################################################
#################### VPC Config ###########################

  azs                         = ["${local.region}a", "${local.region}b", "${local.region}c"]
  vpc_cidr                    = "###ZARF_VAR_VPC_CIDR###"
  vpc_name                    = "###ZARF_VAR_VPC_NAME###"
  database_subnets            = ["###ZARF_VAR_DB_SUBNETS###"]

  create_database_subnet_group       = true
  create_database_subnet_route_table = true


###########################################################
#################### EKS Config ###########################

  cluster_name                = "###ZARF_VAR_EKS_CLUSTER_NAME###"
  eks_k8s_version             = "###ZARF_VAR_EKS_CLUSTER_VERSION###"
  # list of admin's AWS account arn to allow control of KMS keys
  cluster_key_admin_arns      = ["###ZARF_VAR_EKS_ADMIN_ARN_0###","###ZARF_VAR_EKS_ADMIN_ARN_1###"]
  # list of admin's AWS account/group info to allow access to EKS cluster
  #16
  aws_auth_eks_map_users      = [
    {
      userarn  = "###ZARF_VAR_EKS_ADMIN_ARN_0###"
      username = ""
      groups   = ["system:masters"]
    },
    {
      userarn  = "###ZARF_VAR_EKS_ADMIN_ARN_1###"
      username = ""
      groups   = ["system:masters"]
    }
  ]

###########################################################
################## Bastion Config #########################

  bastion_name                = "###ZARF_VAR_BASTION_NAME###"
  bastion_ami_id              = "###ZARF_VAR_BASTION_AMI_ID###"
  # local user in bastion used to ssh
  ssh_user                    = "###ZARF_VAR_BASTION_SSH_USER###"
  
###########################################################
############## Big Bang Dependencies ######################

  keycloak_enabled = true
  # other_addon_enabled = true


#################### Keycloak ###########################

  keycloak_db_password          = "###ZARF_VAR_KEYCLOAK_DB_PASSWORD###"
  kc_db_engine_version          = "###ZARF_VAR_KC_DB_ENGINE_VERSION###"
  kc_db_family                  = "###ZARF_VAR_KC_DB_FAMILY###" # DB parameter group
  kc_db_major_engine_version    = "###ZARF_VAR_KC_DB_MAJOR_ENGINE_VERSION###"         # DB option group
  kc_db_allocated_storage     = var.kc_db_allocated_storage
  kc_db_max_allocated_storage = var.kc_db_max_allocated_storage
  kc_db_instance_class          = "###ZARF_VAR_KC_DB_INSTANCE_CLASS###"
}