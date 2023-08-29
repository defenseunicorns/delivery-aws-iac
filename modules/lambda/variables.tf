variable "enable_password_rotation_lambda" {
  description = "This will enable password rotation for your select users on your selected ec2 instances."
  type        = bool
  default     = false
}
variable "users" {
  description = "List of users to change passwords for password lambda function"
  type        = list(string)
}

variable "instance_ids" {
  description = "List of instances that passwords will be rotated by lambda function"
  type        = list(string)
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for all resources that use a randomized suffix"
  type        = string
  validation {
    condition     = length(var.name_prefix) <= 37
    error_message = "Name Prefix may not be longer than 37 characters."
  }
}

variable "cron_schedule_password_rotation" {
  description = "Schedule for password change function to run on"
  type        = string
  default     = "cron(0 0 1 * ? *)"
}

variable "random_id" {
  description = "random it for unique naming"
  type        = string
  default     = ""
}

variable "slack_notification_enabled" {
  description = "enable slack notifications for password rotation function. If enabled a slack webhook url will also need to be provided for this to work"
  type        = bool
  default     = false
}

variable "slack_webhook_url" {
  description = "value"
  type        = string
  default     = null
}
