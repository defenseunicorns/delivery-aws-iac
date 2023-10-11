data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}


module "password_lambda" {
  source        = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda.git?ref=v6.0.0"
  function_name = "${var.name_prefix}-password-function-${var.random_id}"
  count         = var.enable_password_rotation_lambda ? 1 : 0
  description   = "Lambda Function that performs password rotation on ec2 windows and linux"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 900
  publish       = true
  allowed_triggers = {
    password-rotation = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.cron_eventbridge_rule[count.index].arn
    }
  }
  environment_variables = {
    users                      = join(",", var.users)
    instance_ids               = join(",", var.instance_ids)
    slack_webhook_url          = var.slack_webhook_url
    slack_notification_enabled = var.slack_notification_enabled
  }


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
        #should be variable passed in per instance.
        "arn:${data.aws_partition.current.partition}:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*",
        "arn:${data.aws_partition.current.partition}:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:*",
        "arn:${data.aws_partition.current.partition}:ssm:${var.region}::document/AWS-RunShellScript",
        "arn:${data.aws_partition.current.partition}:ssm:${var.region}::document/AWS-RunPowerShellScript"
      ]
    },
  }
  source_path = "${path.module}/fixtures/functions/password-rotation/lambda_function.py"
}

resource "aws_cloudwatch_event_rule" "cron_eventbridge_rule" {
  count       = var.enable_password_rotation_lambda ? 1 : 0
  name        = "${var.name_prefix}-password-function-trigger-${var.random_id}"
  description = "Monthly trigger for lambda function"
  # schedule_expression = "cron(0 0 1 * ? *)"
  schedule_expression = var.cron_schedule_password_rotation
  event_pattern       = <<EOF
{
  "detail-type": [
    "Scheduled Event"
  ],
  "source": [
    "aws.events"
  ],
  "resources": [
    "${module.password_lambda[0].lambda_function_arn}"
  ]
}
EOF
}

resource "aws_cloudwatch_event_target" "cron_event_target" {
  count     = var.enable_password_rotation_lambda ? 1 : 0
  rule      = aws_cloudwatch_event_rule.cron_eventbridge_rule[count.index].name
  target_id = "TargetFunctionV1"
  arn       = module.password_lambda[0].lambda_function_arn
}
