# mission-init

The Mission Init module demonstrates the questions that will need to be determined
when standing up a new environment. This module will feed the rest of the resources
most of the required information for the modules to function as intended.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.34 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.6.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.34 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ami.init](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_session_context.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_session_context) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_filters"></a> [ami\_filters](#input\_ami\_filters) | n/a | <pre>map(object({<br/>    owners      = list(string)<br/>    most_recent = bool<br/>    filters     = map(list(string))<br/>  }))</pre> | <pre>{<br/>  "bastion": {<br/>    "filters": {<br/>      "name": [<br/>        "al2023-ami-20*-kernel-*-x86_64"<br/>      ]<br/>    },<br/>    "most_recent": true,<br/>    "owners": [<br/>      "amazon"<br/>    ]<br/>  },<br/>  "eks-cpu": {<br/>    "filters": {<br/>      "name": [<br/>        "bottlerocket-aws-k8s-1.29-x86_64-v1.23.0-74970be4"<br/>      ]<br/>    },<br/>    "most_recent": true,<br/>    "owners": [<br/>      "amazon"<br/>    ]<br/>  }<br/>}</pre> | no |
| <a name="input_deploy_id"></a> [deploy\_id](#input\_deploy\_id) | A unique identifier for the deployment | `string` | n/a | yes |
| <a name="input_impact_level"></a> [impact\_level](#input\_impact\_level) | The impact level configuration to use for deployment, i.e. devx, il5, etc.. | `string` | `"devx"` | no |
| <a name="input_permissions_boundary_policy_arn"></a> [permissions\_boundary\_policy\_arn](#input\_permissions\_boundary\_policy\_arn) | The ARN of the permissions boundary to be applied to roles | `string` | n/a | yes |
| <a name="input_stage"></a> [stage](#input\_stage) | The deployment stage, i.e. dev, test, staging etc... | `string` | `"demo"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | n/a |
| <a name="output_amis"></a> [amis](#output\_amis) | n/a |
| <a name="output_aws_caller_identity"></a> [aws\_caller\_identity](#output\_aws\_caller\_identity) | n/a |
| <a name="output_aws_iam_session_context"></a> [aws\_iam\_session\_context](#output\_aws\_iam\_session\_context) | n/a |
| <a name="output_aws_partition"></a> [aws\_partition](#output\_aws\_partition) | n/a |
| <a name="output_azs"></a> [azs](#output\_azs) | n/a |
| <a name="output_deploy_id"></a> [deploy\_id](#output\_deploy\_id) | n/a |
| <a name="output_deployment_requirements"></a> [deployment\_requirements](#output\_deployment\_requirements) | Outputs at mission-init reflect what needs to be decided at start-of-mission - this can be in a tofu root module that connects our opinionated wrappers for vpc, eks, bastion or at the componet level using atmos. |
| <a name="output_permissions_boundary_policy_name"></a> [permissions\_boundary\_policy\_name](#output\_permissions\_boundary\_policy\_name) | n/a |
| <a name="output_region"></a> [region](#output\_region) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
