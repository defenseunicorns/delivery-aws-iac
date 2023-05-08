# terraform-aws-cloudtrail

Terraform module to provision a [CloudTrail](https://aws.amazon.com/cloudtrail/) on AWS.

## Notes

* This module should be used when bootstrapping a new AWS account, to set up a CloudTrail that monitors the activity in the account. It is not meant to be used as part of every terraform deployment in the account.
* See [CloudTrail Best Practices](https://aws.amazon.com/blogs/mt/aws-cloudtrail-best-practices/) for more information on how to configure CloudTrail.
* Provides the choice for the user to either provide an S3 bucket or create a new one with sensible defaults.
* Simplifies the creation of the CloudTrail by using opinionated configuration. If you need more customizability please open an issue so we can add it.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.62.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.62.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudtrail.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.cloudtrail_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.cloudtrail_cloudwatch_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cloudtrail_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudtrail_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_is_multi_region_trail"></a> [is\_multi\_region\_trail](#input\_is\_multi\_region\_trail) | Whether the trail is created in the current region or in all regions. | `bool` | `true` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key ARN to use to encrypt the logs delivered by CloudTrail. | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain logs. | `number` | `365` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the trail | `string` | n/a | yes |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Name of the S3 bucket to use for CloudTrail logs. Required if use\_external\_s3\_bucket is true. | `string` | `null` | no |
| <a name="input_s3_key_prefix"></a> [s3\_key\_prefix](#input\_s3\_key\_prefix) | S3 key prefix for CloudTrail logs | `string` | `"cloudtrail"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all taggable resources | `map(string)` | `{}` | no |
| <a name="input_use_external_s3_bucket"></a> [use\_external\_s3\_bucket](#input\_use\_external\_s3\_bucket) | Whether to use an existing S3 bucket for CloudTrail logs. If false, a new S3 bucket will be created with sensible defaults that checks most (but not all) of the boxes for security. Note that it is best practice to use an S3 bucket in a separate security boundary with limited access (a separate AWS account). See https://aws.amazon.com/blogs/mt/aws-cloudtrail-best-practices/ | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | n/a |
| <a name="output_trail_arn"></a> [trail\_arn](#output\_trail\_arn) | n/a |
| <a name="output_trail_home_region"></a> [trail\_home\_region](#output\_trail\_home\_region) | n/a |
| <a name="output_trail_id"></a> [trail\_id](#output\_trail\_id) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
