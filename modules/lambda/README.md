# AWS Lambda Module

This repository contains Terraform configuration files that create an AWS Lambda Function. 

The module uses a local existing package which is being created via an archive file resource. See example below.

```
data "archive_file" "lambda_archive_file" {
  type        = "zip"
  source_file = var.source_file
  output_path = var.output_path
}
```

## Examples

To view examples for how you can leverage this Lambda Module, please see the [examples](https://github.com/defenseunicorns/delivery-aws-iac/tree/main/examples) directory.