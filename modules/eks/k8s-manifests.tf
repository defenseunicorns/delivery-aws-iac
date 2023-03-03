################################################################################
# VPC-CNI Custom Networking ENIConfig
################################################################################

resource "kubectl_manifest" "eni_config" {
  for_each = toset(module.vpc.intra_subnets)

  yaml_body = <<YAML
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: ${each.value}
spec:
  subnet : ${each.value}
  securityGroups :
    - ${module.eks_blueprints.cluster_security_group_id}
    - ${module.eks_blueprints.worker_node_security_group_id}
YAML
}
