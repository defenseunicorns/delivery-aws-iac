## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.21 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 2.70.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.48.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_kms_key.ws_volume_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_workspaces_workspace.workspace](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/workspaces_workspace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | Optional provider that can be used with the AWS provider | `string` | `""` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources into | `string` | `"us-gov-west-1"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | List of tags to add to every workspace | `map(string)` | <pre>{<br>  "managed_by": "terraform"<br>}</pre> | no |
| <a name="input_directory_id"></a> [directory\_id](#input\_directory\_id) | ID of the AWS Directory service workspaces will use for authentication | `string` | n/a | yes |
| <a name="input_ws_config"></a> [ws\_config](#input\_ws\_config) | List of configurations for an arbitrary number of workspace instances | <pre>map(object({<br>    bundle_id                                 = string<br>    user_name                                 = string<br>    compute_type_name                         = string<br>    user_volume_size_gib                      = number<br>    root_volume_size_gib                      = number<br>    running_mode                              = string<br>    running_mode_auto_stop_timeout_in_minutes = number<br>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_workspaces_info"></a> [workspaces\_info](#output\_workspaces\_info) | n/a |
