###########################################################
################## Global Settings ########################

# Setting region per test case to avoid AWS service quota limits
#region  = "us-east-2" # target AWS region
#region2 = "us-east-1" # RDS backup target AWS region

tags = {
  Environment = "dev"
  Project     = "du-iac-cicd"
}
name_prefix               = "ex-complete"
manage_aws_auth_configmap = true

###########################################################
#################### VPC Config ###########################

vpc_cidr = "10.200.0.0/16"

###########################################################
################## Bastion Config #########################

bastion_ssh_user     = "ec2-user" # local user in bastion used to ssh
bastion_ssh_password = "my-password"
zarf_version         = "v0.24.0-rc4"

###########################################################
#################### EKS Config ###########################

cluster_version = "1.23"

###########################################################
############## Big Bang Dependencies ######################

keycloak_enabled = true


#################### Keycloak ###########################

keycloak_db_password        = "my-password"
kc_db_engine_version        = "14.1"
kc_db_family                = "postgres14" # DB parameter group
kc_db_major_engine_version  = "14"         # DB option group
kc_db_allocated_storage     = 20
kc_db_max_allocated_storage = 100
kc_db_instance_class        = "db.t4g.large"

# #################### EKS Addon #########################
# add other "eks native" marketplace addons and configs to this list
cluster_addons = {
  vpc-cni = {
    most_recent          = true
    before_compute       = true
    configuration_values = <<-JSON
      {
        "env": {
          "AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG": "true",
          "ENABLE_PREFIX_DELEGATION": "true",
          "ENI_CONFIG_LABEL_DEF": "topology.kubernetes.io/zone",
          "WARM_PREFIX_TARGET": "1",
          "ANNOTATE_POD_IP": "true"
        }
      }
    JSON
  }
}


#################### Blueprints addons ###################
#wait false for all addons, as it times out on teardown in the test pipeline
enable_cluster_autoscaler      = true
cluster_autoscaler_helm_config = { wait = false }

enable_amazon_eks_aws_ebs_csi_driver = true
amazon_eks_aws_ebs_csi_driver_config = { wait = false }

enable_metrics_server      = true
metrics_server_helm_config = { wait = false }

enable_aws_node_termination_handler      = true
aws_node_termination_handler_helm_config = { wait = false }

enable_calico      = true
calico_helm_config = { wait = false }
