output "s3_bucket" {
  description = "S3 Bucket Name"
  value       = module.s3_bucket.s3_bucket_id
}
output "dynamodb_name" {
  description = "Name of DynmoDB table"
  value       = aws_dynamodb_table.loki_dynamodb[0].name
}
