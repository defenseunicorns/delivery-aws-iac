
locals {
  // Context for base shall be IL5
  // These settings shall map to the inputs for the offical eks module.
  // It caputures our settings such that defaults for the offical module don't
  // change out from under us.
  base_eks_config = merge(local.aws_eks_source_defaults, {
    vpc_id                           = var.vpc_config.vpc_id
    subnet_ids                       = var.vpc_config.private_subnets //Private subnets by default for base
    control_plane_subnet_ids         = var.vpc_config.private_subnets
    tags                             = data.context_tags.this.tags
    cluster_name                     = data.context_label.this.rendered
    iam_role_permissions_boundary    = local.iam_role_permissions_boundary
    cluster_version                  = var.eks_config_opts.cluster_version
    cluster_endpoint_public_access   = false //No public access
    cluster_endpoint_private_access  = true  //Private access requred
    kms_key_administrators           = local.kms_key_admin_arns
    self_managed_node_group_defaults = local.base_self_managed_node_group_defaults
    self_managed_node_groups         = local.base_self_managed_node_groups
  })
}
