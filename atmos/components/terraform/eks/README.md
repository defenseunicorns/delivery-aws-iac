## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.34 |
| <a name="requirement_context"></a> [context](#requirement\_context) | ~> 0.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.69.0 |
| <a name="provider_context"></a> [context](#provider\_context) | 0.4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_eks"></a> [aws\_eks](#module\_aws\_eks) | git::https://github.com/terraform-aws-modules/terraform-aws-eks.git | v20.24.0 |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_session_context.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_session_context) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| context_config.this | data source |
| context_label.this | data source |
| context_tags.this | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks_config_opts"></a> [eks\_config\_opts](#input\_eks\_config\_opts) | EKS Configuration options to be determined by mission needs. | <pre>object({<br/>    cluster_version         = optional(string, "1.30")<br/>    kms_key_admin_usernames = optional(list(string), [])<br/>    kms_key_admin_arns      = optional(list(string), [])<br/>  })</pre> | <pre>{<br/>  "cluster_version": "1.30"<br/>}</pre> | no |
| <a name="input_eks_sensitive_config_opts"></a> [eks\_sensitive\_config\_opts](#input\_eks\_sensitive\_config\_opts) | n/a | <pre>object({<br/>    eks_sensitive_opt1 = optional(string)<br/>    eks_sensitive_opt2 = optional(string)<br/>  })</pre> | n/a | yes |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | Existing VPC configuration for EKS | <pre>object({<br/>    vpc_id                     = string<br/>    subnet_ids                 = list(string)<br/>    azs                        = list(string)<br/>    private_subnet_ids         = list(string)<br/>    intra_subnet_ids           = list(string)<br/>    database_subnets           = optional(list(string))<br/>    database_subnet_group_name = optional(string)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_context"></a> [context](#output\_context) | n/a |
| <a name="output_context_tags"></a> [context\_tags](#output\_context\_tags) | n/a |
| <a name="output_eks_config"></a> [eks\_config](#output\_eks\_config) | Use Impact Level from context to set the default config for EKS This object will be used to configure the official AWS EKS module. Outputting for illustration purposes. |
| <a name="output_eks_opt_config_out"></a> [eks\_opt\_config\_out](#output\_eks\_opt\_config\_out) | n/a |
| <a name="output_eks_sensitive_opt_config_out"></a> [eks\_sensitive\_opt\_config\_out](#output\_eks\_sensitive\_opt\_config\_out) | n/a |
| <a name="output_eks_vpc_attrs"></a> [eks\_vpc\_attrs](#output\_eks\_vpc\_attrs) | n/a |
| <a name="output_example_resource_name_suffix"></a> [example\_resource\_name\_suffix](#output\_example\_resource\_name\_suffix) | n/a |
