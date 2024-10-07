locals {

  base_self_managed_node_group_defaults = {
    //instance_type                          = null # conflicts with instance_requirements settings
    //key_name                               = module.self_managed_node_group_keypair.key_pair_name
    key_name                               = "TODO: key_name"
    iam_role_permissions_boundary          = local.iam_role_permissions_boundary
    update_launch_template_default_version = true
    use_mixed_instances_policy             = true

    /*
    instance_requirements = {
      allowed_instance_types = ["m6i.4xlarge", "m5a.4xlarge"] #this should be adjusted to the appropriate instance family if reserved instances are being utilized
      memory_mib = {
        min = 64000
      }
      vcpu_count = {
        min = 16
      }
    }
    */

    placement = {
      tenancy = "dedicated"
    }

    pre_bootstrap_userdata = <<-EOT
        yum install -y amazon-ssm-agent
        systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
      EOT

    post_userdata = <<-EOT
        echo "Bootstrap successfully completed! You can further apply config or install to run after bootstrap if needed"
      EOT

    # bootstrap_extra_args used only when you pass custom_ami_id. Allows you to change the Container Runtime for Nodes
    # e.g., bootstrap_extra_args="--use-max-pods false --container-runtime containerd"
    bootstrap_extra_args = "--use-max-pods false"

    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore      = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore",
      AmazonElasticFileSystemFullAccess = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonElasticFileSystemFullAccess"
    }

    # enable discovery of autoscaling groups by cluster-autoscaler
    autoscaling_group_tags = merge(
      {
        "k8s.io/cluster-autoscaler/enabled" : true,
        "k8s.io/cluster-autoscaler/${data.context_label.this.rendered}" : "owned"
    })

    metadata_options = {
      #https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#metadata-options
      http_endpoint               = "enabled"
      http_put_response_hop_limit = 2
      http_tokens                 = "optional" # set to "enabled" to enforce IMDSv2, default for upstream terraform-aws-eks module
    }

    tags = {
      subnet_type                            = "private",
      cluster                                = data.context_label.this.rendered
      "aws-node-termination-handler/managed" = true # only need this if NTH is enabled. This is due to aws blueprints using this resource and causing the tags to flap on every apply https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/blob/257677adeed1be54326637cf919cf24df6ad7c06/main.tf#L1554-L1564
    }
  }
  //TODO: node groups should not contain info common to all node group options
  base_uds_core_self_mg_node_group = {
    uds_ng = {
      //ami_type = "BOTTLEROCKET_x86_64" //TODO: is ami_type needed when specfic id provided?
      ami_id        = var.eks_config_opts.default_ami_id
      instance_type = null # conflicts with instance_requirements settings
      instance_requirements = {
        allowed_instance_types = ["m6i.4xlarge", "m5a.4xlarge"] #this should be adjusted to the appropriate instance family if reserved instances are being utilized
        memory_mib = {
          min = 64000
        }
        vcpu_count = {
          min = 16
        }
      }
      min_size     = 3
      max_size     = 5
      desired_size = 3

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 100
            volume_type = "gp3"
          }
        }
        xvdb = {
          device_name = "/dev/xvdb"
          ebs = {
            volume_size = 100
            volume_type = "gp3"
            #need to add and create EBS key
          }
        }
      }

      bootstrap_extra_args = <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default.
        [settings.host-containers.admin]
        enabled = true

        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true

        # extra args added
        # [settings.kernel]
        # lockdown = "integrity"

        #[settings.kubernetes.node-labels]
        #label1 = "da-bb-nodes"
      EOT
    }
  }

  base_keycloak_self_mg_node_group = {
    keycloak_ng_sso = {
      //platform = "bottlerocket"
      ami_id        = lookup(var.uds_config_opts, "keycloak_node_group_ami_id", var.eks_config_opts.default_ami_id)
      instance_type = null # conflicts with instance_requirements settings
      min_size      = 2
      max_size      = 2
      desired_size  = 2
      //TODO: this should always be true
      //key_name = var.uds_config_opts.keycloak_enabled ? module.key_pair[0].key_pair_name : null
      key_name = var.uds_config_opts.keycloak_enabled ? "foo" : null

      bootstrap_extra_args = <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default, but can be disabled explicitly.
        [settings.host-containers.admin]
        enabled = false

        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true

        # extra args added
        [settings.kernel]
        lockdown = "integrity"

        [settings.kubernetes.node-labels]
        label1 = "sso"
        label2 = "bb-core"

        [settings.kubernetes.node-taints]
        dedicated = "experimental:PreferNoSchedule"
        special = "true:NoSchedule"
      EOT
    }
  }

  additional_self_managed_node_groups = [
    for group in var.eks_config_opts.additional_self_managed_node_groups : {
      for ng_name, ng_details in group : ng_name => ng_details
    }
  ]


  base_self_managed_node_groups = merge(
    local.base_uds_core_self_mg_node_group,
    var.uds_config_opts.keycloak_enabled ? local.base_keycloak_self_mg_node_group : {},
    local.additional_self_managed_node_groups...
  )
}
