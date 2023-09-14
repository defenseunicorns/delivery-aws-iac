# AWS Lambda Module

This repository contains highly opinionated lambda modules that include the lambda function code.

## Usage

If you want to create new functionality, you can do so by writing your lambda code and storing it in its own directory. For example, the code for the password rotation function can be stored in the directory `fixtures/functions/password-rotation/lambda_function.py`. In your `main.tf` file, use the following `source_path`:

`source_path = "${path.module}/fixtures/functions/password-rotation/lambda_function.py"`


You will also need to identify and specify the necessary IAM permissions for your function by adding the appropriate policy statements in `main.tf`.

```
assume_role_policy_statements = {
    account_root = {
      effect  = "Allow",
      actions = ["sts:AssumeRole"],
      principals = {
        account_principal = {
          type        = "Service",
          identifiers = ["lambda.amazonaws.com"]
        }
      }
    }
  }
  attach_policy_statements = true
  policy_statements = {
    ec2 = {
      effect    = "Allow",
      actions   = ["ec2:DescribeInstances", "ec2:DescribeImages"]
      resources = ["*"]
      condition = {
        stringequals_condition = {
          test     = "StringEquals"
          variable = "aws:RequestedRegion"
          values   = [var.region]
        }
        stringequals_condition2 = {
          test     = "StringEquals"
          variable = "aws:PrincipalAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      }
    },
    secretsmanager = {
      effect = "Allow",
      actions = [
        "secretsmanager:CreateSecret",
        "secretsmanager:PutResourcePolicy",
        "secretsmanager:DescribeSecret",
        "secretsmanager:UpdateSecret"
      ]
      resources = ["arn:${data.aws_partition.current.partition}:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
    },
    logs = {
      effect = "Allow",
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = ["arn:${data.aws_partition.current.partition}:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
    },
    ssm = {
      effect = "Allow"
      actions = [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation",
        "ssm:PutParameter",
        "ssm:GetParameter",
        "ssm:DeleteParameter"
      ]
      resources = [
        "arn:${data.aws_partition.current.partition}:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*",
        "arn:${data.aws_partition.current.partition}:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:*",
        "arn:${data.aws_partition.current.partition}:ssm:${var.region}::document/AWS-RunShellScript",
        "arn:${data.aws_partition.current.partition}:ssm:${var.region}::document/AWS-RunPowerShellScript"
      ]
    },
```

### Lambda Password Module

This module deploys a Python function that securely generates and rotates EC2 instance passwords for Windows and EC2 Linux instances using AWS Systems Manager (SSM), Secrets Manager, and Parameter Store. It also sets up an Amazon EventBridge cron job to run every 30 days this cron job can be modified as seen in fixtures.common.tfvars.

To use this module, provide the users who exist on the instances and the instance IDs as shown in the example mentioned below.

You can also enable slack notifications in the function in order to do so you must first create a slack app and get the webhook url.

Once you have that you can set the variable slack_notification_enabled = true and set the slack_webhook_url = (your webhook url)

## Examples

To see examples of how to leverage this Lambda Module, please refer to the [examples](https://github.com/defenseunicorns/delivery-aws-iac/tree/main/examples) directory.

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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_password_lambda"></a> [password\_lambda](#module\_password\_lambda) | git::https://github.com/terraform-aws-modules/terraform-aws-lambda.git | v6.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.cron_eventbridge_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.cron_event_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cron_schedule_password_rotation"></a> [cron\_schedule\_password\_rotation](#input\_cron\_schedule\_password\_rotation) | Schedule for password change function to run on | `string` | `"cron(0 0 1 * ? *)"` | no |
| <a name="input_enable_password_rotation_lambda"></a> [enable\_password\_rotation\_lambda](#input\_enable\_password\_rotation\_lambda) | This will enable password rotation for your select users on your selected ec2 instances. | `bool` | `false` | no |
| <a name="input_instance_ids"></a> [instance\_ids](#input\_instance\_ids) | List of instances that passwords will be rotated by lambda function | `list(string)` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Name prefix for all resources that use a randomized suffix | `string` | n/a | yes |
| <a name="input_random_id"></a> [random\_id](#input\_random\_id) | random it for unique naming | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | n/a | yes |
| <a name="input_slack_notification_enabled"></a> [slack\_notification\_enabled](#input\_slack\_notification\_enabled) | enable slack notifications for password rotation function. If enabled a slack webhook url will also need to be provided for this to work | `bool` | `false` | no |
| <a name="input_slack_webhook_url"></a> [slack\_webhook\_url](#input\_slack\_webhook\_url) | value | `string` | `null` | no |
| <a name="input_users"></a> [users](#input\_users) | List of users to change passwords for password lambda function | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_password_function_arn"></a> [lambda\_password\_function\_arn](#output\_lambda\_password\_function\_arn) | Arn for lambda password function |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
