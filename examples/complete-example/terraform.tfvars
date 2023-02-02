# Rename this file to <filename>.tfvars and fill in the values
# Run terraform command to specify using the tfvars file `terraform plan -var-file tf-state-backend.tfvars`
# Variables can also be set via environment variables

###########################################################
################## Global Settings ########################

region               = "us-east-2"    # target AWS region
region2              = "us-east-1"    # RDS backup target AWS region
account              = "100008675309" # target AWS account
aws_profile          = "du-dev"       # local AWS profile to be used for deployment
aws_admin_1_username = "Bob.Marley"   # enables eks access & ssh access to bastion
aws_admin_2_username = "Jane.Doe"     # enables eks access & ssh access to bastion

###########################################################
#################### VPC Config ###########################

vpc_cidr = "10.200.0.0/16"
vpc_name = "my-vpc"

###########################################################
#################### EKS Config ###########################

cluster_name            = "my-eks"
eks_k8s_version         = "1.24"
instance_type           = "m5.xlarge"
launch_template_os      = "amazonlinux2eks"
create_launch_template  = true
custom_ami_id           = ""
create_iam_role         = false
public_ip               = false
enable_monitoring       = false
enable_metadata_options = false
desired_size            = 3
max_size                = 10
min_size                = 3

# EKS Managed Add-ons
cni_add_on     = true
coredns        = true
kube_proxy     = true
ebs_csi_add_on = true

#K8s Add-ons
metric_server                = true
aws_node_termination_handler = true
cluster_autoscaler           = true

###########################################################
################## Bastion Config #########################

bastion_name         = "my-bastion"
bastion_ami_id       = "ami-04afd6ecf73c0a579" # AWS linux 2 CIS STIG // "ami-000d4884381edb14c" # AWS linux 2
bastion_ssh_user     = "ec2-user"              # local user in bastion used to ssh
bastion_ssh_password = "my-password"

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
