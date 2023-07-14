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

## Examples

To see examples of how to leverage this Lambda Module, please refer to the [examples](https://github.com/defenseunicorns/delivery-aws-iac/tree/main/examples) directory.
