# Global Vars

# variable "aws_profile" {
#   type        = string
#   description = "AWS Profile"
# }

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_id" {
  type        = string
  description = "VPC id"
}

### Bastion Module

variable "name" {
  type        = string
  description = "Name of Bastion"
  default     = ""
}

variable "ami_id" {
  type        = string
  description = "ID of AMI to use for Bastion"
  default     = ""
}

variable "allowed_public_ips" {
  type        = list(string)
  description = "List of public IPs to allow SSH access from"
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

variable "ec2_key_name" {
  type        = string
  description = "Name of keypair to associate with instance"
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

variable "requires_eip" {
  type        = bool
  description = "Whether or not the instance should have an Elastic IP associated to it"
  default     = false
}

variable "user_data" {
  type        = string
  description = "(Optional) The user data to provide when launching the instance"
  default     = ""
}

variable "role_name" {
  type        = string
  description = "Name to give IAM role created for instance profile"
  default     = ""
}

variable "policy_arns" {
  type        = list(string)
  description = "List of IAM policy ARNs to attach to the instance profile"
  default     = []
}

variable "policy_content" {
  type        = string
  description = "Policy body. Use this to add a custom policy to your instance profile (Optional)"
  default     = ""
}

variable "root_volume_config" {
  type = object({
    volume_type = any
    volume_size = any
  })
  default = {
    volume_type = "gp2"
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

variable "acl" {
  description = "The canned ACL to apply. Defaults to 'private'"
  type        = string
  default     = "private"
}

variable "versioning_enabled" {
  description = "Enable versioning. Once you version-enable a bucket, it can never return to an unversioned state. You can, however, suspend versioning on that bucket."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error"
  type        = bool
  default     = true
}

variable "logging" {
  description = "Map containing access bucket logging configuration."
  type        = map(string)
  default     = {}
}

variable "enable_event_queue" {
  description = "Toggle to optionally generate events on object writes, and add them to an SQS queue. Defaults to false"
  type        = bool
  default     = false
}

variable "enable_kms_key_rotation" {
  description = "Toggle to optionally enable kms key rotation. Defaults to true"
  type        = bool
  default     = true
}

variable "bucket_public_access_block" {
  description = "Toggle to optionally block public s3 access. Defaults to true"
  type        = bool
  default     = true
}

#####################################################
##################### user data #####################


variable "ssh_user" {
  default = "ubuntu"
}

variable "enable_hourly_cron_updates" {
  default = "false"
}

variable "keys_update_frequency" {
  default = ""
}

variable "user_data_file" {
  default = "templates/user_data.sh"
}

variable "additional_user_data_script" {
  default = ""
}

variable "ssh_public_key_names" {
  default = ["user1", "user2", "admin"]
  type    = list(string)
}

variable "cluster_sops_policy_arn" {
  description = "value of the policy arn for the cluster sops policy"
  default = ""
}

variable "add_sops_policy" {
  description = "value of the policy arn for the cluster sops policy"
  type = bool
  default = "true"
}