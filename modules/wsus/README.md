<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.21 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 2.70.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ebs_volume.wsus_volumes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_instance.wsus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.wsus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.windows_update_443](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.windows_update_80](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.wsus_in](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_volume_attachment.wsus_ebs_att](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [random_password.admin_local_pass](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_secretsmanager_secret_version.ad](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [template_file.additional_drive](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.wsus](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.wsus_domain_connect_userdata](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ad_domain_name"></a> [ad\_domain\_name](#input\_ad\_domain\_name) | n/a | `string` | `"cnap.dso.mil"` | no |
| <a name="input_ad_domain_user"></a> [ad\_domain\_user](#input\_ad\_domain\_user) | n/a | `string` | `"admin"` | no |
| <a name="input_ad_domain_user_password"></a> [ad\_domain\_user\_password](#input\_ad\_domain\_user\_password) | n/a | `string` | `""` | no |
| <a name="input_ad_password_secret_name"></a> [ad\_password\_secret\_name](#input\_ad\_password\_secret\_name) | Optional. Name of secrets manager secret containing domain user password. Will override 'ad\_domain\_user\_password' if set | `string` | `""` | no |
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_ami"></a> [ami](#input\_ami) | n/a | `string` | `"ami-003666d32869fa0d3"` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | Profile to use for authentication with AWS | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to be used for deployment | `string` | n/a | yes |
| <a name="input_critical_update"></a> [critical\_update](#input\_critical\_update) | n/a | `string` | `"1"` | no |
| <a name="input_customer"></a> [customer](#input\_customer) | n/a | `string` | `"CNAP"` | no |
| <a name="input_definition_updates"></a> [definition\_updates](#input\_definition\_updates) | n/a | `string` | `"0"` | no |
| <a name="input_disabled_products"></a> [disabled\_products](#input\_disabled\_products) | wsus disabled products | `string` | `"*language packs*,*drivers*"` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | n/a | `list(string)` | <pre>[<br>  "10.122.20.24,10.122.20.58"<br>]</pre> | no |
| <a name="input_driver_sets"></a> [driver\_sets](#input\_driver\_sets) | n/a | `string` | `"0"` | no |
| <a name="input_drivers"></a> [drivers](#input\_drivers) | n/a | `string` | `"0"` | no |
| <a name="input_enabled_products"></a> [enabled\_products](#input\_enabled\_products) | wsus enabled products | `string` | `"windows server 2008*,windows server 2012*,windows server 2016*,windows server 2019*"` | no |
| <a name="input_envname"></a> [envname](#input\_envname) | n/a | `string` | `"DEV"` | no |
| <a name="input_envtype"></a> [envtype](#input\_envtype) | n/a | `string` | n/a | yes |
| <a name="input_extra_ebs_blocks"></a> [extra\_ebs\_blocks](#input\_extra\_ebs\_blocks) | Extra volumes for data storage | <pre>list(object({<br>    device_name = string<br>    volume_size = number<br>    volume_type = string<br>  }))</pre> | <pre>[<br>  {<br>    "device_name": "xvdf",<br>    "volume_size": 400,<br>    "volume_type": "gp2"<br>  }<br>]</pre> | no |
| <a name="input_feature_packs"></a> [feature\_packs](#input\_feature\_packs) | n/a | `string` | `"0"` | no |
| <a name="input_instance_profile"></a> [instance\_profile](#input\_instance\_profile) | n/a | `string` | `"p1-citrix-ad-server-profile"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | n/a | `string` | `"m5.xlarge"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | n/a | `string` | `"p1cnap"` | no |
| <a name="input_language"></a> [language](#input\_language) | wsus language | `string` | `"en"` | no |
| <a name="input_local_password"></a> [local\_password](#input\_local\_password) | n/a | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-gov-west-1"` | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | wsus root drive size (GB) | `number` | `75` | no |
| <a name="input_root_volume_type"></a> [root\_volume\_type](#input\_root\_volume\_type) | wsus root drive type | `string` | `"gp2"` | no |
| <a name="input_security_updates"></a> [security\_updates](#input\_security\_updates) | n/a | `string` | `"0"` | no |
| <a name="input_service_packs"></a> [service\_packs](#input\_service\_packs) | n/a | `string` | `"0"` | no |
| <a name="input_sg_name_overide"></a> [sg\_name\_overide](#input\_sg\_name\_overide) | n/a | `string` | `""` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | n/a | `string` | `"subnet-0df49a358784309d8"` | no |
| <a name="input_targeting_mode"></a> [targeting\_mode](#input\_targeting\_mode) | WSUS targeting mode Client = use GPO Server = manually assign | `string` | `"Server"` | no |
| <a name="input_timezone"></a> [timezone](#input\_timezone) | n/a | `string` | `"GMT Standard Time"` | no |
| <a name="input_tools"></a> [tools](#input\_tools) | n/a | `string` | `"0"` | no |
| <a name="input_update_rollups"></a> [update\_rollups](#input\_update\_rollups) | n/a | `string` | `"0"` | no |
| <a name="input_updates"></a> [updates](#input\_updates) | n/a | `string` | `"0"` | no |
| <a name="input_upgrades"></a> [upgrades](#input\_upgrades) | n/a | `string` | `"0"` | no |
| <a name="input_userdata"></a> [userdata](#input\_userdata) | n/a | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | `"vpc-067376be5c597ae82"` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | n/a | `string` | `"sg-0280c0fcc12b630c2"` | no |
| <a name="input_wu_inbound_cidrs"></a> [wu\_inbound\_cidrs](#input\_wu\_inbound\_cidrs) | n/a | `list(string)` | <pre>[<br>  "10.122.0.0/16"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_wsus_instance_id"></a> [wsus\_instance\_id](#output\_wsus\_instance\_id) | n/a |
| <a name="output_wsus_private_ip"></a> [wsus\_private\_ip](#output\_wsus\_private\_ip) | n/a |
| <a name="output_wsus_sg_id"></a> [wsus\_sg\_id](#output\_wsus\_sg\_id) | n/a |
<!-- END_TF_DOCS -->
