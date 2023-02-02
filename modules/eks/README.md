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
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.9 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks_blueprints"></a> [eks\_blueprints](#module\_eks\_blueprints) | git::https://github.com/ntwkninja/terraform-aws-eks-blueprints.git | v4.21.1 |
| <a name="module_eks_blueprints_kubernetes_addons"></a> [eks\_blueprints\_kubernetes\_addons](#module\_eks\_blueprints\_kubernetes\_addons) | git::https://github.com/ntwkninja/terraform-aws-eks-blueprints.git//modules/kubernetes-addons | v4.21.1 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.self_managed_ng](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.auth_eks_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.self_managed_ng](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document.self_managed_ng_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account"></a> [aws\_account](#input\_aws\_account) | n/a | `string` | `""` | no |
| <a name="input_aws_auth_eks_map_users"></a> [aws\_auth\_eks\_map\_users](#input\_aws\_auth\_eks\_map\_users) | List of map of users to add to aws-auth configmap | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_aws_node_termination_handler"></a> [aws\_node\_termination\_handler](#input\_aws\_node\_termination\_handler) | enables k8 node termination handler | `bool` | `true` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | `""` | no |
| <a name="input_bastion_role_arn"></a> [bastion\_role\_arn](#input\_bastion\_role\_arn) | ARN of role authorized kubectl access | `string` | `""` | no |
| <a name="input_bastion_role_name"></a> [bastion\_role\_name](#input\_bastion\_role\_name) | Name of role authorized kubectl access | `string` | `""` | no |
| <a name="input_block_device_mappings"></a> [block\_device\_mappings](#input\_block\_device\_mappings) | List of block device mappings for the instance | `list(map(string))` | <pre>[<br>  {<br>    "device_name": "/dev/xvda",<br>    "volume_size": 50,<br>    "volume_type": "gp3"<br>  },<br>  {<br>    "device_name": "/dev/xvdf",<br>    "iops": 3000,<br>    "throughput": 125,<br>    "volume_size": 80,<br>    "volume_type": "gp3"<br>  },<br>  {<br>    "device_name": "/dev/xvdg",<br>    "iops": 3000,<br>    "throughput": 125,<br>    "volume_size": 100,<br>    "volume_type": "gp3"<br>  }<br>]</pre> | no |
| <a name="input_bootstrap_extra_args"></a> [bootstrap\_extra\_args](#input\_bootstrap\_extra\_args) | Additional bootstrap arguments for the instance | `string` | `"--use-max-pods false"` | no |
| <a name="input_cluster_autoscaler"></a> [cluster\_autoscaler](#input\_cluster\_autoscaler) | enables the cluster autoscaler | `bool` | `true` | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Enable private access to the cluster endpoint | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Enable public access to the cluster endpoint | `bool` | `false` | no |
| <a name="input_cluster_kms_key_additional_admin_arns"></a> [cluster\_kms\_key\_additional\_admin\_arns](#input\_cluster\_kms\_key\_additional\_admin\_arns) | List of ARNs of additional users to add to KMS key policy | `list(string)` | `[]` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of cluster - used by Terratest for e2e test automation | `string` | `""` | no |
| <a name="input_cni_add_on"></a> [cni\_add\_on](#input\_cni\_add\_on) | enables eks cni add-on | `bool` | `true` | no |
| <a name="input_control_plane_subnet_ids"></a> [control\_plane\_subnet\_ids](#input\_control\_plane\_subnet\_ids) | Subnet IDs for control plane | `list(string)` | `[]` | no |
| <a name="input_coredns"></a> [coredns](#input\_coredns) | enables eks coredns | `bool` | `true` | no |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | Do you want to create an iam role | `bool` | `false` | no |
| <a name="input_create_launch_template"></a> [create\_launch\_template](#input\_create\_launch\_template) | Do you want to create a launch template? | `bool` | `true` | no |
| <a name="input_custom_ami_id"></a> [custom\_ami\_id](#input\_custom\_ami\_id) | The ami id of your custom ami | `string` | `""` | no |
| <a name="input_desired_size"></a> [desired\_size](#input\_desired\_size) | Desired size of the cluster | `number` | `3` | no |
| <a name="input_ebs_csi_add_on"></a> [ebs\_csi\_add\_on](#input\_ebs\_csi\_add\_on) | enables the ebs csi driver add-on | `bool` | `true` | no |
| <a name="input_eks_k8s_version"></a> [eks\_k8s\_version](#input\_eks\_k8s\_version) | Kubernetes version to use for EKS cluster | `string` | `"1.23"` | no |
| <a name="input_enable_metadata_options"></a> [enable\_metadata\_options](#input\_enable\_metadata\_options) | Enable metadata options for the instance | `bool` | `false` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Enable CloudWatch monitoring for the instance | `bool` | `false` | no |
| <a name="input_format_mount_nvme_disk"></a> [format\_mount\_nvme\_disk](#input\_format\_mount\_nvme\_disk) | Format the NVMe disk during the instance launch | `bool` | `true` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type for the instances in the cluster | `string` | `""` | no |
| <a name="input_kube_proxy"></a> [kube\_proxy](#input\_kube\_proxy) | enables eks kube proxy | `bool` | `true` | no |
| <a name="input_launch_template_os"></a> [launch\_template\_os](#input\_launch\_template\_os) | The name of your launch template os | `string` | `"amazonlinux2eks"` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum size of the cluster | `number` | `10` | no |
| <a name="input_metric_server"></a> [metric\_server](#input\_metric\_server) | enables k8 metrics server | `bool` | `true` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum size of the cluster | `number` | `3` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `""` | no |
| <a name="input_node_group_name"></a> [node\_group\_name](#input\_node\_group\_name) | The name of your node groups | `string` | `"self_mg"` | no |
| <a name="input_pre_userdata"></a> [pre\_userdata](#input\_pre\_userdata) | n/a | `string` | `"yum install -y amazon-ssm-agent\nsystemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent\n"` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private subnet IDs | `list(string)` | `[]` | no |
| <a name="input_public_ip"></a> [public\_ip](#input\_public\_ip) | Associate a public IP address with the instance | `bool` | `false` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | Public subnet IDs | `list(string)` | `[]` | no |
| <a name="input_source_security_group_id"></a> [source\_security\_group\_id](#input\_source\_security\_group\_id) | List of additional rules to add to cluster security group | `string` | `""` | no |
| <a name="input_tenancy"></a> [tenancy](#input\_tenancy) | Tenancy of the cluster | `string` | `"dedicated"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configure_kubectl"></a> [configure\_kubectl](#output\_configure\_kubectl) | Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig |
| <a name="output_eks_cluster_certificate_authority_data"></a> [eks\_cluster\_certificate\_authority\_data](#output\_eks\_cluster\_certificate\_authority\_data) | EKS cluster certificate authority data |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | EKS cluster endpoint |
| <a name="output_eks_cluster_id"></a> [eks\_cluster\_id](#output\_eks\_cluster\_id) | EKS cluster ID |
| <a name="output_eks_managed_nodegroup_arns"></a> [eks\_managed\_nodegroup\_arns](#output\_eks\_managed\_nodegroup\_arns) | EKS managed node group arns |
| <a name="output_eks_managed_nodegroup_ids"></a> [eks\_managed\_nodegroup\_ids](#output\_eks\_managed\_nodegroup\_ids) | EKS managed node group ids |
| <a name="output_eks_managed_nodegroup_role_name"></a> [eks\_managed\_nodegroup\_role\_name](#output\_eks\_managed\_nodegroup\_role\_name) | EKS managed node group role name |
| <a name="output_eks_managed_nodegroup_status"></a> [eks\_managed\_nodegroup\_status](#output\_eks\_managed\_nodegroup\_status) | EKS managed node group status |
| <a name="output_eks_managed_nodegroups"></a> [eks\_managed\_nodegroups](#output\_eks\_managed\_nodegroups) | EKS managed node groups |
| <a name="output_eks_oidc_provider_arn"></a> [eks\_oidc\_provider\_arn](#output\_eks\_oidc\_provider\_arn) | EKS OIDC provider ARN |
| <a name="output_region"></a> [region](#output\_region) | AWS region |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
