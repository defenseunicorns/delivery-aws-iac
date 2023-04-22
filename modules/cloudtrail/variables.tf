variable "name" {
  description = "Name of the trail"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ARN to use to encrypt the logs delivered by CloudTrail."
  type        = string
}

variable "is_multi_region_trail" {
  description = "Whether the trail is created in the current region or in all regions."
  type        = bool
  default     = true
}

variable "s3_key_prefix" {
  description = "S3 key prefix for CloudTrail logs"
  type        = string
  default     = "cloudtrail"
}

variable "use_external_s3_bucket" {
  description = "Whether to use an existing S3 bucket for CloudTrail logs. If false, a new S3 bucket will be created with sensible defaults that checks most (but not all) of the boxes for security. Note that it is best practice to use an S3 bucket in a separate security boundary with limited access (a separate AWS account). See https://aws.amazon.com/blogs/mt/aws-cloudtrail-best-practices/"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket to use for CloudTrail logs. Required if use_external_s3_bucket is true."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all taggable resources"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Number of days to retain logs."
  type        = number
  default     = 30
}
