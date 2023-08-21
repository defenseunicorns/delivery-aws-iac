###########################################################
################## Global Settings ########################

tags = {
  Environment = "dev"
  Project     = "du-iac-cicd"
}
name_prefix               = "ex-complete"
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
zarf_version = "v0.26.3"

###########################################################
#################### EKS Config ###########################
# renovate: datasource=endoflife-date depName=amazon-eks versioning=loose extractVersion=^(?<version>.*)-eks.+$
cluster_version = "1.27"
eks_use_mfa     = false

###########################################################
############## Big Bang Dependencies ######################

keycloak_enabled = true # provisions keycloak dedicated nodegroup

# #################### EKS Addons #########################
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
  aws-ebs-csi-driver = {
    most_recent = true
  }
}


#################### Blueprints addons ###################
#wait false for all addons, as it times out on teardown in the test pipeline

enable_amazon_eks_aws_efs_csi_driver = true
aws_efs_csi_driver = {
  wait          = false
  chart_version = "2.4.8"
}

enable_amazon_eks_aws_ebs_csi_driver = true
enable_gp3_default_storage_class     = true
storageclass_reclaim_policy          = "Delete" # set to `Retain` for non-dev use

enable_aws_node_termination_handler = true
aws_node_termination_handler = {
  wait = false
  # renovate: datasource=docker depName=public.ecr.aws/aws-ec2/helm/aws-node-termination-handler
  chart_version = "v0.21.0"
}

enable_cluster_autoscaler = true
cluster_autoscaler = {
  wait = false
  # renovate: datasource=github-tags depName=kubernetes/autoscaler extractVersion=^cluster-autoscaler-chart-(?<version>.*)$
  chart_version = "v9.29.1"
}

enable_metrics_server = true
metrics_server = {
  wait = false
  # renovate: datasource=github-tags depName=kubernetes-sigs/metrics-server extractVersion=^metrics-server-helm-chart-(?<version>.*)$
  chart_version = "v3.10.0"
}

enable_calico = true
calico = {
  wait = false
  # renovate: datasource=github-tags depName=projectcalico/calico
  chart_version = "v3.26.1"
}

######################################################
################## Lambda Config #####################

################# Password Rotation ##################
enable_password_rotation_lambda = true
# Add users that will be on your ec2 instances.
users = ["ec2-user", "Administrator"]

cron_schedule_password_rotation = "cron(0 0 1 * ? *)"

slack_notification_enabled = true

slack_webhook_url = "<your slack webhook url>"
