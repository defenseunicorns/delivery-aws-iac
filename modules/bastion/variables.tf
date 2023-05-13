# Global Vars

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_id" {
  type        = string
  description = "VPC id"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS Key ARN to use for encryption"
}

variable "access_logs_bucket_name" {
  type        = string
  description = "Name of S3 bucket to use to store access logs"
}

variable "access_logs_target_prefix" {
  type        = string
  description = "Prefix for all log object keys for the access log."
  default     = "bastion-session-logs/"
}

variable "enable_sqs_events_on_bastion_login" {
  description = "If true, generates an SQS event whenever an object is created in the Session Logs S3 bucket, which happens whenever someone logs in to the Bastion."
  type        = bool
  default     = false
}

### Bastion Module

variable "name" {
  type        = string
  description = "Name of Bastion"
}

variable "instance_type" {
  type        = string
  description = "Instance type to use for Bastion"
  default     = "m5.large"
}

variable "ami_id" {
  type        = string
  description = "ID of AMI to use for Bastion"
  default     = ""
}

variable "allowed_public_ips" {
  type        = list(string)
  description = "List of public IPs or private IP (internal) of Software Defined Perimeter to allow SSH access from"
  default     = []
}

variable "ami_name_filter" {
  type        = string
  description = "Filter for AMI using this name. Accepts wildcards"
  default     = ""
}

variable "ami_virtualization_type" {
  type        = string
  description = "Filter for AMI using this virtualization type"
  default     = ""
}

variable "ami_canonical_owner" {
  type        = string
  description = "Filter for AMI using this canonical owner ID"
  default     = null
}

variable "security_group_ids" {
  type        = list(any)
  description = "List of security groups to associate with instance"
  default     = []
}

variable "subnet_id" {
  type        = string
  description = "IDs of subnets to deploy the instance in"
  default     = ""
}

variable "subnet_name" {
  type        = string
  description = "Names of subnets to deploy the instance in"
  default     = ""
}

variable "policy_arns" {
  type        = list(string)
  description = "List of IAM policy ARNs to attach to the instance profile"
  default     = []
}

variable "policy_content" {
  type        = string
  description = "JSON IAM Policy body. Use this to add a custom policy to your instance profile (Optional)"
  default     = null
  validation {
    condition     = var.policy_content == null || try(jsondecode(var.policy_content), null) != null
    error_message = "The policy_content variable must be valid JSON."
  }
}

variable "root_volume_config" {
  type = object({
    volume_type = any
    volume_size = any
  })
  default = {
    volume_type = "gp3"
    volume_size = "20"
  }
}

variable "assign_public_ip" {
  description = "Determines if an instance gets a public IP assigned at launch time"
  type        = bool
  default     = false
}

variable "eni_attachment_config" {
  description = "Optional list of enis to attach to instance"
  type = list(object({
    network_interface_id = string
    device_index         = string
  }))
  default = null
}

variable "permissions_boundary" {
  description = "(Optional) The ARN of the policy that is used to set the permissions boundary for the role."
  type        = string
  default     = null
}

#### S3 Bucket

variable "session_log_bucket_name_prefix" {
  description = "Name prefix of S3 bucket to store session logs"
  type        = string
  validation {
    condition     = length(var.session_log_bucket_name_prefix) <= 37
    error_message = "Bucket name prefixes may not be longer than 37 characters."
  }
}

variable "log_archive_days" {
  description = "Number of days to wait before archiving to Glacier"
  type        = number
  default     = 30
}

variable "log_expire_days" {
  description = "Number of days to wait before deleting"
  type        = number
  default     = 365
}

variable "enable_log_to_s3" {
  description = "Enable Session Manager to Log to S3"
  type        = bool
  default     = true
}

variable "enable_log_to_cloudwatch" {
  description = "Enable Session Manager to Log to CloudWatch Logs"
  type        = bool
  default     = true
}

#####################################################
##################### user data #####################


variable "ssh_user" {
  description = "Username to use when accessing the instance using SSH"
  type        = string
  default     = "ubuntu"
}

variable "additional_user_data_script" {
  description = "Additional user data script to run on instance boot"
  type        = string
  default     = ""
}

variable "ssm_enabled" {
  description = "Enable SSM agent"
  type        = bool
  default     = true
}

variable "ssh_password" {
  description = "Password for SSH access if SSM authentication is enabled"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "cloudwatch_logs_retention" {
  description = "Number of days to retain Session Logs in CloudWatch"
  type        = number
  default     = 365
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for storing SSM Session Logs"
  type        = string
  default     = "/ssm/session-logs"
}

variable "linux_shell_profile" {
  description = "The ShellProfile to use for linux based machines."
  default     = ""
  type        = string
}

variable "windows_shell_profile" {
  description = "The ShellProfile to use for windows based machines."
  default     = ""
  type        = string
}

variable "tenancy" {
  description = "The tenancy of the instance (if the instance is running in a VPC). Valid values are 'default' or 'dedicated'."
  type        = string
  default     = "default"
}

variable "zarf_version" {
  description = "The version of Zarf to use"
  type        = string
  default     = ""
}

variable "enable_bastion_terraform_permissions" {
  description = "Enable Terraform permissions for Bastion"
  type        = bool
  default     = false
}
