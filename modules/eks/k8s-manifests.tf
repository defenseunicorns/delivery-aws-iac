################################################################################
# VPC-CNI Custom Networking ENIConfig
#################################################################################

locals {
  security_groups = [
    module.aws_eks.cluster_primary_security_group_id != "" ? "- ${module.aws_eks.cluster_primary_security_group_id}" : "",
    module.aws_eks.node_security_group_id != "" ? "- ${module.aws_eks.node_security_group_id}" : "",
    module.aws_eks.cluster_security_group_id != "" ? "- ${module.aws_eks.cluster_security_group_id}" : ""
  ]
}

resource "kubectl_manifest" "eni_config" {
  for_each = zipmap(local.azs, var.vpc_cni_custom_subnet)

  yaml_body = <<YAML
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: ${each.key}
spec:
  subnet : ${each.value}
  securityGroups :
${join("\n", local.security_groups)}
YAML

  depends_on = [
    module.aws_eks.cluster_addons
  ]
}
