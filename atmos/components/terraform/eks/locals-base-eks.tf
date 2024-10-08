
locals {
  // Context for base shall be IL5
  // These settings shall map to the inputs for the offical eks module.
  // It caputures our settings such that defaults for the offical module don't
  // change out from under us.
  base_eks_config = {
    vpc_id                          = var.vpc_config.vpc_id
    subnet_ids                      = var.vpc_config.private_subnets //Private subnets by default for base
    control_plane_subnet_ids        = var.vpc_config.private_subnets
    tags                            = data.context_tags.this.tags
    cluster_name                    = data.context_label.this.rendered
    iam_role_permissions_boundary   = local.iam_role_permissions_boundary
    cluster_version                 = var.eks_config_opts.cluster_version
    cluster_addons                  = []
    cluster_endpoint_public_access  = false //No public access
    cluster_endpoint_private_access = true  //Private access requred
    kms_key_administrators          = local.kms_key_admin_arns
    cluster_ip_family               = "ipv4"
    //cluster_service_ipv4_cidr                = ""
    attach_cluster_encryption_policy           = true
    cluster_endpoint_public_access_cidrs       = ["0.0.0.0/0"]
    self_managed_node_group_defaults           = local.base_self_managed_node_group_defaults
    self_managed_node_groups                   = local.base_self_managed_node_groups
    eks_managed_node_group_defaults            = {}
    eks_managed_node_groups                    = {}
    dataplane_wait_duration                    = "4m"
    cluster_timeouts                           = {}
    access_entries                             = {}
    authentication_mode                        = "API_AND_CONFIG_MAP"
    enable_cluster_creator_admin_permissions   = true
    cluster_security_group_additional_rules    = {}
    cluster_additional_security_group_ids      = []
    create_cluster_security_group              = true
    cluster_security_group_id                  = ""
    cluster_security_group_name                = ""
    cluster_security_group_use_name_prefix     = true
    cluster_security_group_description         = "EKS cluster security group"
    cluster_security_group_tags                = {}
    create_kms_key                             = true
    kms_key_description                        = ""
    kms_key_deletion_window_in_days            = null
    enable_kms_key_rotation                    = true
    kms_key_enable_default_policy              = true
    kms_key_owners                             = []
    kms_key_users                              = []
    kms_key_service_users                      = []
    kms_key_source_policy_documents            = []
    kms_key_override_policy_documents          = []
    kms_key_aliases                            = []
    cluster_enabled_log_types                  = ["audit", "api", "authenticator"]
    create_cloudwatch_log_group                = true
    cloudwatch_log_group_retention_in_days     = 90
    cloudwatch_log_group_kms_key_id            = ""
    cluster_tags                               = {}
    create_cluster_primary_security_group_tags = true
    cloudwatch_log_group_tags                  = {}
    //cloudwatch_log_group_class                 = ""
  }
}
