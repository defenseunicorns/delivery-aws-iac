################################################################################
# VPC-CNI Custom Networking ENIConfig
#################################################################################

resource "kubectl_manifest" "eni_config" {
  for_each = length(var.vpc_cni_custom_subnet == 0) ? {} : zipmap(local.azs, var.vpc_cni_custom_subnet)

  yaml_body = yamlencode({
    apiVersion = "crd.k8s.amazonaws.com/v1alpha1"
    kind       = "ENIConfig"
    metadata = {
      name = each.key
    }
    spec = {
      securityGroups = compact([module.aws_eks.cluster_primary_security_group_id, module.aws_eks.node_security_group_id, module.aws_eks.cluster_security_group_id])
      subnet         = each.value
    }
  })

  lifecycle {
    precondition {
      condition     = length(var.vpc_cni_custom_subnet) == length(local.azs) || length(var.vpc_cni_custom_subnet) == 0
      error_message = "the number of items in var.vpc_cni_custom_subnet must match the number of items in local.azs"
    }
  }
}
