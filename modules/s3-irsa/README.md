# AWS S3-IRSA Module

This repository contains Terraform configuration files that create an S3 bucket and DynamoDB table, both are secured with server-side encryption (SSE) using a KMS key. This module configures the S3 bucket and DynamoDB table to be used with Loki for the storage of Chunks and Indexes.

## Examples

To view examples for how you can leverage this S3-IRSA Module, please see the [examples](https://github.com/defenseunicorns/delivery-aws-iac/tree/main/examples) directory.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.72 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.72 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | v3.14.0 |

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.loki_dynamodb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_policy.dynamodb_irsa_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.irsa_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.dynamodb_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket_logging.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_policy.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_versioning.versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.dynamo_irsa_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.irsa_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logging_bucket_id"></a> [access\_logging\_bucket\_id](#input\_access\_logging\_bucket\_id) | The ID of the S3 bucket to which access logs are written | `string` | `null` | no |
| <a name="input_access_logging_bucket_prefix"></a> [access\_logging\_bucket\_prefix](#input\_access\_logging\_bucket\_prefix) | The prefix to use for all log object keys. Ex: 'logs/' | `string` | `"s3-irsa-bucket-access-logs/"` | no |
| <a name="input_access_logging_enabled"></a> [access\_logging\_enabled](#input\_access\_logging\_enabled) | If true, set up access logging of the S3 bucket to a different S3 bucket, provided by the variables `logging_bucket_id` and `logging_bucket_path`. Caution: Enabling this will likely cause LOTS of access logs, as one is generated each time the bucket is accessed and Loki will be hitting the bucket a lot! | `bool` | `false` | no |
| <a name="input_dynamodb_enabled"></a> [dynamodb\_enabled](#input\_dynamodb\_enabled) | Is dynamoDB enabled | `bool` | `false` | no |
| <a name="input_eks_oidc_provider_arn"></a> [eks\_oidc\_provider\_arn](#input\_eks\_oidc\_provider\_arn) | EKS OIDC Provider ARN e.g., arn:aws:iam::<ACCOUNT-ID>:oidc-provider/<var.eks\_oidc\_provider> | `string` | n/a | yes |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | If true, destroys all objects in the bucket when the bucket is destroyed so that the bucket can be destroyed without error. Objects that are destroyed in this way are NOT recoverable. | `bool` | `false` | no |
| <a name="input_irsa_iam_permissions_boundary"></a> [irsa\_iam\_permissions\_boundary](#input\_irsa\_iam\_permissions\_boundary) | IAM permissions boundary for IRSA roles | `string` | `""` | no |
| <a name="input_irsa_iam_policies"></a> [irsa\_iam\_policies](#input\_irsa\_iam\_policies) | IAM Policies for IRSA IAM role | `list(string)` | `[]` | no |
| <a name="input_irsa_iam_role_name"></a> [irsa\_iam\_role\_name](#input\_irsa\_iam\_role\_name) | IAM role name for IRSA | `string` | `""` | no |
| <a name="input_irsa_iam_role_path"></a> [irsa\_iam\_role\_path](#input\_irsa\_iam\_role\_path) | IAM role path for IRSA roles | `string` | `"/"` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS Key ARN to use for encryption | `string` | n/a | yes |
| <a name="input_kubernetes_namespace"></a> [kubernetes\_namespace](#input\_kubernetes\_namespace) | Kubernetes namespace for IRSA | `string` | `"default"` | no |
| <a name="input_kubernetes_service_account"></a> [kubernetes\_service\_account](#input\_kubernetes\_service\_account) | Kubernetes service account for IRSA | `string` | `"default"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Name prefix for all resources that use a randomized suffix | `string` | n/a | yes |
| <a name="input_policy_name_prefix"></a> [policy\_name\_prefix](#input\_policy\_name\_prefix) | IAM Policy name prefix | `string` | `"irsa-policy"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamodb_name"></a> [dynamodb\_name](#output\_dynamodb\_name) | Name of DynmoDB table |
| <a name="output_irsa_role"></a> [irsa\_role](#output\_irsa\_role) | ARN of the IRSA Role |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | S3 Bucket Name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
