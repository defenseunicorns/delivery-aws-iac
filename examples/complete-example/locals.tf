locals {

###########################################################
################## Global Settings ########################

  region                      = "us-east-2"  # target AWS region
  region2                     = "us-east-1"  # RDS backup target AWS region
  account                     = "730071141898"  # target AWS account
  aws_profile                 = "du-dev"  # local AWS profile to be used for deployment


  tags = {
    Blueprint                 = "${replace(basename(path.cwd), "_", "-")}"  # tag names based on the directory name
    GithubRepo                = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
  
###########################################################
#################### VPC Config ###########################

  azs                         = ["${local.region}a", "${local.region}b", "${local.region}c"]
  vpc_cidr                    = "10.200.0.0/16"
  vpc_name                    = "my-vpc"
  database_subnets            = ["10.200.7.0/24", "10.200.8.0/24", "10.200.9.0/24"]

  create_database_subnet_group       = true
  create_database_subnet_route_table = true


###########################################################
#################### EKS Config ###########################

  cluster_name                = "my-eks"
  eks_k8s_version             = "1.23"
  # list of admin's AWS account arn to allow control of KMS keys
  cluster_key_admin_arns      = ["arn:aws:iam::${local.account}:user/Gabe","arn:aws:iam::${local.account}:user/Rex"]
  # list of admin's AWS account/group info to allow access to EKS cluster
  #16
  aws_auth_eks_map_users      = [
    {
      userarn  = "arn:aws:iam::${local.account}:user/rex"
      username = "rex"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${local.account}:user/gabe"
      username = "gabe"
      groups   = ["system:masters"]
    }
  ]

###########################################################
################## Bastion Config #########################

  bastion_name                = "my-bastion"
  assign_public_ip            = true   # comment out if behind Software Defined Perimeter / VPN
  bastion_ami_id              = "ami-000d4884381edb14c"
  # local user in bastion used to ssh
  ssh_user                    = "ec2-user"
  # list of keys that match names in public_keys folder (without file extension)
  ssh_public_key_names        = ["rex","gabe"]
  # list of admin Publc IPs
  allowed_public_ips          = ["216.147.124.97/32","173.27.185.4/32"]

###########################################################
############## Big Bang Dependencies ######################

  keycloak_enabled = true
  # other_addon_enabled = true


#################### Keycloak ###########################

  keycloak_db_password          = "my-password" 
  kc_db_engine_version          = "14.1"
  kc_db_family                  = "postgres14" # DB parameter group
  kc_db_major_engine_version    = "14"         # DB option group
  kc_db_allocated_storage       = 20
  kc_db_max_allocated_storage   = 100
  kc_db_instance_class          = "db.t4g.large"
}