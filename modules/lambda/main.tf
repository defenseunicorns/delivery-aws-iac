module "lambda" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda.git?ref=v5.0.0"

  function_name  = var.function_name
  description    = var.function_description
  handler        = var.function_handler
  runtime        = var.lambda_runtime
  timeout        = var.timeout
  create_package = false

  local_existing_package = var.output_path

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
  policy_statements        = var.policy_statements
}
