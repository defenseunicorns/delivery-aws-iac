## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.48.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_directory_service_directory.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/directory_service_directory) | resource |
| [aws_iam_role.workspace_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.self-service-access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.service-access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_workspaces_directory.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/workspaces_directory) | resource |
| [null_resource.cert-setup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_secretsmanager_secret_version.ad](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ad_connector_customer_dns_ips"></a> [ad\_connector\_customer\_dns\_ips](#input\_ad\_connector\_customer\_dns\_ips) | The DNS IP addresses of the domain to connect to | `list(string)` | n/a | yes |
| <a name="input_ad_connector_name"></a> [ad\_connector\_name](#input\_ad\_connector\_name) | The fully qualified name for the directory, such as corp.example.com | `string` | n/a | yes |
| <a name="input_ad_connector_size"></a> [ad\_connector\_size](#input\_ad\_connector\_size) | The size of the directory (Small or Large are accepted values) | `string` | `"Large"` | no |
| <a name="input_ad_connector_subnet_ids"></a> [ad\_connector\_subnet\_ids](#input\_ad\_connector\_subnet\_ids) | The identifiers of the subnets for the directory servers (2 subnets in 2 different AZs) | `list(string)` | n/a | yes |
| <a name="input_ad_connector_vpc_id"></a> [ad\_connector\_vpc\_id](#input\_ad\_connector\_vpc\_id) | The identifier of the VPC that the directory is in | `string` | n/a | yes |
| <a name="input_ad_secret_name"></a> [ad\_secret\_name](#input\_ad\_secret\_name) | Name of a secret in secretsmanager that contains the username and password for AD | `string` | n/a | yes |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | n/a | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | n/a | yes |
| <a name="input_change_compute_type"></a> [change\_compute\_type](#input\_change\_compute\_type) | Whether WorkSpaces directory users can change the compute type (bundle) for their workspace | `bool` | `false` | no |
| <a name="input_custom_security_group_id"></a> [custom\_security\_group\_id](#input\_custom\_security\_group\_id) | The identifier of your custom security group. Should relate to the same VPC, where workspaces reside in. | `string` | `""` | no |
| <a name="input_default_ou"></a> [default\_ou](#input\_default\_ou) | Default OU to place new workspaces in | `string` | n/a | yes |
| <a name="input_enable_internet_access"></a> [enable\_internet\_access](#input\_enable\_internet\_access) | This will allow outbound Internet access from your WorkSpaces when using an Internet Gateway. Leave disabled if you are using a Network Address Translation (NAT) configuration | `bool` | `false` | no |
| <a name="input_increase_volume_size"></a> [increase\_volume\_size](#input\_increase\_volume\_size) | Whether WorkSpaces directory users can increase the volume size of the drives on their workspace | `bool` | `false` | no |
| <a name="input_rebuild_workspace"></a> [rebuild\_workspace](#input\_rebuild\_workspace) | Whether WorkSpaces directory users can rebuild the operating system of a workspace to its original state | `bool` | `false` | no |
| <a name="input_restart_workspace"></a> [restart\_workspace](#input\_restart\_workspace) | Whether WorkSpaces directory users can restart their workspace | `bool` | `true` | no |
| <a name="input_setup_dod_ca"></a> [setup\_dod\_ca](#input\_setup\_dod\_ca) | Whether to register the DoD CAs with the AD connector using a local exec operation. Note, assumes bash as interpreter | `bool` | `false` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The identifiers of the subnets where the directory resides | `list(string)` | n/a | yes |
| <a name="input_switch_running_mode"></a> [switch\_running\_mode](#input\_switch\_running\_mode) | Whether WorkSpaces directory users can switch the running mode of their workspace | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_directory_service_id"></a> [directory\_service\_id](#output\_directory\_service\_id) | n/a |
| <a name="output_directory_service_ips"></a> [directory\_service\_ips](#output\_directory\_service\_ips) | n/a |
| <a name="output_workspace_directory_id"></a> [workspace\_directory\_id](#output\_workspace\_directory\_id) | n/a |
