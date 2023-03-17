# AWS EKS Module

This repository contains Terraform configuration files that create an Amazon Elastic Kubernetes Service (EKS) cluster. This module sets various paremeters for this cluster including the cluster name, version, VPC information, security group rules, and user and role mappings. Additionally, it sets up self-managed node groups for the EKS cluster.

## Examples

To view examples for how you can leverage this EKS Module, please see the [examples](https://github.com/defenseunicorns/iac/tree/main/examples) directory.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.9 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.4.1 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.14 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.9 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | >= 1.14 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_eks"></a> [aws\_eks](#module\_aws\_eks) | git::https://github.com/terraform-aws-modules/terraform-aws-eks.git | v19.10.0 |
| <a name="module_eks_blueprints_kubernetes_addons"></a> [eks\_blueprints\_kubernetes\_addons](#module\_eks\_blueprints\_kubernetes\_addons) | git::https://github.com/aws-ia/terraform-aws-eks-blueprints.git//modules/kubernetes-addons | v4.24.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.auth_eks_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [kubectl_manifest.eni_config](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [aws_ami.amazonlinux2eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document.managed_ng_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.self_managed_ng_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_amazon_eks_aws_ebs_csi_driver_config"></a> [amazon\_eks\_aws\_ebs\_csi\_driver\_config](#input\_amazon\_eks\_aws\_ebs\_csi\_driver\_config) | configMap for AWS EBS CSI Driver add-on | `any` | `{}` | no |
| <a name="input_amazon_eks_coredns_config"></a> [amazon\_eks\_coredns\_config](#input\_amazon\_eks\_coredns\_config) | Configuration for Amazon CoreDNS EKS add-on | `any` | `{}` | no |
| <a name="input_amazon_eks_kube_proxy_config"></a> [amazon\_eks\_kube\_proxy\_config](#input\_amazon\_eks\_kube\_proxy\_config) | ConfigMap for Amazon EKS Kube-Proxy add-on | `any` | `{}` | no |
| <a name="input_amazon_eks_vpc_cni"></a> [amazon\_eks\_vpc\_cni](#input\_amazon\_eks\_vpc\_cni) | The VPC CNI add-on configuration.<br><br>enabled - (Optional) Whether to enable the add-on. Defaults to false.<br>before\_compute - (Optional) Whether to create the add-on before the compute resources. Defaults to true.<br>most\_recent - (Optional) Whether to use the most recent version of the add-on. Defaults to true.<br>resolve\_conflict - (Optional) How to resolve parameter value conflicts between the add-on and the cluster. Defaults to OVERWRITE. Valid values: OVERWRITE, NONE, PRESERVE.<br>configuration\_values - (Optional) A map of configuration values for the add-on. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon for supported values. | <pre>object({<br>    enabled              = bool<br>    before_compute       = bool<br>    most_recent          = bool<br>    resolve_conflict     = string<br>    configuration_values = map(any) # hcl format later to be json encoded<br>  })</pre> | <pre>{<br>  "before_compute": true,<br>  "configuration_values": {<br>    "AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG": "true",<br>    "ENABLE_PREFIX_DELEGATION": "true",<br>    "ENI_CONFIG_LABEL_DEF": "topology.kubernetes.io/zone",<br>    "WARM_PREFIX_TARGET": "1"<br>  },<br>  "enabled": false,<br>  "most_recent": true,<br>  "resolve_conflict": "OVERWRITE"<br>}</pre> | no |
| <a name="input_aws_account"></a> [aws\_account](#input\_aws\_account) | n/a | `string` | `""` | no |
| <a name="input_aws_admin_usernames"></a> [aws\_admin\_usernames](#input\_aws\_admin\_usernames) | A list of one or more AWS usernames with authorized access to KMS and EKS resources | `list(string)` | `[]` | no |
| <a name="input_aws_auth_users"></a> [aws\_auth\_users](#input\_aws\_auth\_users) | List of map of users to add to aws-auth configmap | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_aws_node_termination_handler_helm_config"></a> [aws\_node\_termination\_handler\_helm\_config](#input\_aws\_node\_termination\_handler\_helm\_config) | AWS Node Termination Handler Helm Chart config | `any` | `{}` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | `""` | no |
| <a name="input_bastion_role_arn"></a> [bastion\_role\_arn](#input\_bastion\_role\_arn) | ARN of role authorized kubectl access | `string` | `""` | no |
| <a name="input_bastion_role_name"></a> [bastion\_role\_name](#input\_bastion\_role\_name) | Name of role authorized kubectl access | `string` | `""` | no |
| <a name="input_cluster_autoscaler_helm_config"></a> [cluster\_autoscaler\_helm\_config](#input\_cluster\_autoscaler\_helm\_config) | Cluster Autoscaler Helm Chart config | `any` | <pre>{<br>  "set": [<br>    {<br>      "name": "extraArgs.expander",<br>      "value": "priority"<br>    },<br>    {<br>      "name": "expanderPriorities",<br>      "value": "100:\n  - .*-spot-2vcpu-8mem.*\n90:\n  - .*-spot-4vcpu-16mem.*\n10:\n  - .*\n"<br>    }<br>  ]<br>}</pre> | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Enable private access to the cluster endpoint | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Enable public access to the cluster endpoint | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of cluster - used by Terratest for e2e test automation | `string` | `""` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version to use for EKS cluster | `string` | `"1.23"` | no |
| <a name="input_control_plane_subnet_ids"></a> [control\_plane\_subnet\_ids](#input\_control\_plane\_subnet\_ids) | Subnet IDs for control plane | `list(string)` | `[]` | no |
| <a name="input_create_aws_auth_configmap"></a> [create\_aws\_auth\_configmap](#input\_create\_aws\_auth\_configmap) | Determines whether to create the aws-auth configmap. NOTE - this is only intended for scenarios where the configmap does not exist (i.e. - when using only self-managed node groups). Most users should use `manage_aws_auth_configmap` | `bool` | `false` | no |
| <a name="input_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#input\_eks\_managed\_node\_groups) | Managed node groups configuration | `any` | `{}` | no |
| <a name="input_enable_amazon_eks_aws_ebs_csi_driver"></a> [enable\_amazon\_eks\_aws\_ebs\_csi\_driver](#input\_enable\_amazon\_eks\_aws\_ebs\_csi\_driver) | Enable EKS Managed AWS EBS CSI Driver add-on; enable\_amazon\_eks\_aws\_ebs\_csi\_driver and enable\_self\_managed\_aws\_ebs\_csi\_driver are mutually exclusive | `bool` | `false` | no |
| <a name="input_enable_amazon_eks_coredns"></a> [enable\_amazon\_eks\_coredns](#input\_enable\_amazon\_eks\_coredns) | Enable Amazon EKS CoreDNS add-on | `bool` | `false` | no |
| <a name="input_enable_amazon_eks_kube_proxy"></a> [enable\_amazon\_eks\_kube\_proxy](#input\_enable\_amazon\_eks\_kube\_proxy) | Enable Kube Proxy add-on | `bool` | `false` | no |
| <a name="input_enable_aws_node_termination_handler"></a> [enable\_aws\_node\_termination\_handler](#input\_enable\_aws\_node\_termination\_handler) | Enable AWS Node Termination Handler add-on | `bool` | `false` | no |
| <a name="input_enable_cluster_autoscaler"></a> [enable\_cluster\_autoscaler](#input\_enable\_cluster\_autoscaler) | Enable Cluster autoscaler add-on | `bool` | `false` | no |
| <a name="input_enable_metrics_server"></a> [enable\_metrics\_server](#input\_enable\_metrics\_server) | Enable metrics server add-on | `bool` | `false` | no |
| <a name="input_kms_key_administrators"></a> [kms\_key\_administrators](#input\_kms\_key\_administrators) | List of ARNs of additional administrator users to add to KMS key policy | `list(string)` | `[]` | no |
| <a name="input_manage_aws_auth_configmap"></a> [manage\_aws\_auth\_configmap](#input\_manage\_aws\_auth\_configmap) | Determines whether to manage the aws-auth configmap | `bool` | `false` | no |
| <a name="input_metrics_server_helm_config"></a> [metrics\_server\_helm\_config](#input\_metrics\_server\_helm\_config) | Metrics Server Helm Chart config | `any` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `""` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private subnet IDs | `list(string)` | `[]` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | Public subnet IDs | `list(string)` | `[]` | no |
| <a name="input_self_managed_node_group_defaults"></a> [self\_managed\_node\_group\_defaults](#input\_self\_managed\_node\_group\_defaults) | Map of self-managed node group default configurations | `any` | `{}` | no |
| <a name="input_self_managed_node_groups"></a> [self\_managed\_node\_groups](#input\_self\_managed\_node\_groups) | Self-managed node groups configuration | `any` | `{}` | no |
| <a name="input_source_security_group_id"></a> [source\_security\_group\_id](#input\_source\_security\_group\_id) | List of additional rules to add to cluster security group | `string` | `""` | no |
| <a name="input_tenancy"></a> [tenancy](#input\_tenancy) | Tenancy of the cluster | `string` | `"dedicated"` | no |
| <a name="input_vpc_cni_custom_subnet"></a> [vpc\_cni\_custom\_subnet](#input\_vpc\_cni\_custom\_subnet) | Subnet to put pod ENIs in | `list(string)` | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_eks"></a> [aws\_eks](#output\_aws\_eks) | all EKS cluster outputs, just for debugging |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | EKS cluster certificate authority data |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | EKS cluster endpoint |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the EKS cluster |
| <a name="output_cluster_status"></a> [cluster\_status](#output\_cluster\_status) | status of the EKS cluster |
| <a name="output_managed_nodegroups"></a> [managed\_nodegroups](#output\_managed\_nodegroups) | EKS managed node groups |
| <a name="output_oidc_provider"></a> [oidc\_provider](#output\_oidc\_provider) | The OpenID Connect identity provider (issuer URL without leading `https://`) |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | EKS OIDC provider ARN |
| <a name="output_region"></a> [region](#output\_region) | AWS region |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
