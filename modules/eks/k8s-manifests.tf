################################################################################
# VPC-CNI Custom Networking ENIConfig
################################################################################
locals {
  vpc_cni_custom_subnet_map = { for key, value in var.vpc_cni_custom_subnet : key => value }
}

# using lookup function below to deal with terraform's "for_each not existing.." race condition errors.
# We fail on purpose looking up "NOTHING" in an empty map.
# lookup() is considered a "non-eager" terraform function allowing you to work around this issue.
# see: https://github.com/clowdhaus/terraform-for-each-unknown
resource "kubectl_manifest" "vpc_cni_eni_config" {
  for_each = local.vpc_cni_custom_subnet_map

  yaml_body = <<YAML
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: ${lookup({}, "NOTHING", each.value)}
spec:
  subnet : ${lookup({}, "NOTHING", each.value)}
  securityGroups :
    - ${module.aws_eks.cluster_primary_security_group_id}
    - ${module.aws_eks.node_security_group_id}
YAML
}
