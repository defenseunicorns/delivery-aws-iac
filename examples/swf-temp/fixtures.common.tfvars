###########################################################
################## Global Settings ########################

tags = {
  Environment = "dev"
  Project     = "swf-temp"
}
name_prefix               = "swf-temp"
manage_aws_auth_configmap = true

###########################################################
#################### VPC Config ###########################

vpc_cidr              = "10.200.0.0/16"
secondary_cidr_blocks = ["100.64.0.0/16"] #https://aws.amazon.com/blogs/containers/optimize-ip-addresses-usage-by-pods-in-your-amazon-eks-cluster/

###########################################################
################## Bastion Config #########################

bastion_ssh_user     = "ec2-user" # local user in bastion used to ssh
bastion_ssh_password = "my-password"
# renovate: datasource=github-tags depName=defenseunicorns/zarf
zarf_version          = "v0.26.3"
bastion_instance_type = "m7i.xlarge"

###########################################################
#################### EKS Config ###########################
# renovate: datasource=endoflife-date depName=amazon-eks versioning=loose extractVersion=^(?<version>.*)-eks.+$
cluster_version = "1.27"

enable_gp3_default_storage_class = true
storageclass_reclaim_policy      = "Delete" # set to `Retain` for non-dev use

###########################################################
############## Big Bang Dependencies ######################

# keycloak_enabled = true


#################### Keycloak ###########################

keycloak_db_password        = "my-password"
kc_db_engine_version        = "15.3"
kc_db_family                = "postgres15" # DB parameter group
kc_db_major_engine_version  = "15"         # DB option group
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
          "ANNOTATE_POD_IP": "true",
          "POD_SECURITY_GROUP_ENFORCING_MODE": "standard"
        }
      }
    JSON
  }
  coredns = {
    preserve    = true
    most_recent = true

    timeouts = {
      create = "25m"
      delete = "10m"
    }
  }
  kube-proxy = {
    most_recent = true
  }
}


#################### Blueprints addons ###################
#wait false for all addons, as it times out on teardown in the test pipeline

enable_efs = true

enable_amazon_eks_aws_ebs_csi_driver = true
amazon_eks_aws_ebs_csi_driver_config = {
  wait        = false
  most_recent = true
}

enable_aws_node_termination_handler = true
aws_node_termination_handler_helm_config = {
  wait = false
  # renovate: datasource=docker depName=public.ecr.aws/aws-ec2/helm/aws-node-termination-handler
  version = "v0.21.0"
}

enable_cluster_autoscaler = true
cluster_autoscaler_helm_config = {
  wait = false
  # renovate: datasource=github-tags depName=kubernetes/autoscaler extractVersion=^cluster-autoscaler-chart-(?<version>.*)$
  version = "v9.28.0"
  set = [
    {
      name  = "extraArgs.expander"
      value = "priority"
    },
    {
      name = "image.tag"
      # renovate: datasource=github-tags depName=kubernetes/autoscaler extractVersion=^cluster-autoscaler-(?<version>.*)$
      value = "v1.27.1"
    }
  ]
}

enable_metrics_server = true
metrics_server_helm_config = {
  wait = false
  # renovate: datasource=github-tags depName=kubernetes-sigs/metrics-server extractVersion=^metrics-server-helm-chart-(?<version>.*)$
  version = "v3.10.0"
}

enable_calico = true
calico_helm_config = {
  wait = false
  # renovate: datasource=github-tags depName=projectcalico/calico
  version = "v3.25.1"
}

######################################################
################## Lambda Config #####################

################# Password Rotation ##################
enable_password_rotation_lambda = false
# Add users that will be on your ec2 instances.
users = ["ec2-user", "Administrator"]

cron_schedule_password_rotation = "cron(0 0 1 * ? *)"
