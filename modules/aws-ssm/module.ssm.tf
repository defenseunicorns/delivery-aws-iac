module "ssm" {
  source                    = "bridgecrewio/session-manager/aws"
  version                   = "0.4.2"
  bucket_name               = "my-session-logs"
  access_log_bucket_name    = "my-session-access-logs"
  vpc_id                    = var.vpc_id
  tags                      = {
                                Function = "ssm"
                              }
  enable_log_to_s3          = true
  enable_log_to_cloudwatch  = true
  # vpc_endpoints_enabled     = true # enabled in vpc module
}