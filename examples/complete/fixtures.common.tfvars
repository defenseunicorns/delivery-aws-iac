###########################################################
################## Global Settings ########################

region  = "us-east-1" # target AWS region
region2 = "us-east-2" # RDS backup target AWS region
# default_tags = {
#   Environment = "dev"
#   Project     = "ci-eks"
#   Owner       = "ci"
# }
manage_aws_auth_configmap = true

###########################################################
#################### VPC Config ###########################

vpc_cidr        = "10.200.0.0/16"
vpc_name_prefix = "ex-complete-vpc-"

###########################################################
################## Bastion Config #########################

bastion_name_prefix  = "ex-complete-bastion-"
bastion_ssh_user     = "ec2-user" # local user in bastion used to ssh
bastion_ssh_password = "my-password"
zarf_version         = "v0.24.0-rc4"

###########################################################
#################### EKS Config ###########################

cluster_name_prefix = "ex-complete-eks-"
cluster_version     = "1.23"

###########################################################
############## Big Bang Dependencies ######################

keycloak_enabled = true
# other_addon_enabled = true


#################### Keycloak ###########################

keycloak_db_password        = "my-password"
kc_db_engine_version        = "14.1"
kc_db_family                = "postgres14" # DB parameter group
kc_db_major_engine_version  = "14"         # DB option group
kc_db_allocated_storage     = 20
kc_db_max_allocated_storage = 100
kc_db_instance_class        = "db.t4g.large"

#################### EKS Addon #########################
amazon_eks_vpc_cni = {
  enable            = true
  before_compute    = true
  most_recent       = true
  resolve_conflicts = "OVERWRITE"
  preserve          = true
  configuration_values = {
    # Reference https://aws.github.io/aws-eks-best-practices/reliability/docs/networkmanagement/#cni-custom-networking
    AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
    ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone" # allows vpc-cni to use topology labels to determine which subnet to deploy an ENI in

    # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
    ENABLE_PREFIX_DELEGATION = "true"
    WARM_PREFIX_TARGET       = "1"
  }
}
