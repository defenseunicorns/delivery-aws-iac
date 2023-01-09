variable "region" {
  type        = string
  description = "AWS region"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones where subnets will be created"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs"
}

variable "zone_id" {
  type        = string
  default     = ""
  description = "Route53 DNS Zone ID"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "Bastion instance type"
}

variable "user_data" {
  type        = list(string)
  default     = []
  description = "User data content"
}

variable "ssh_key_path" {
  type        = string
  description = "Save location for ssh public keys generated by the module"
  default     = ".ssh"
}

variable "generate_ssh_key" {
  type        = bool
  description = "Whether or not to generate an SSH key"
  default     = true
}

variable "security_groups" {
  type        = list(string)
  description = "List of Security Group IDs allowed to connect to the bastion host"
  default = []
}

variable "root_block_device_encrypted" {
  type        = bool
  default     = false
  description = "Whether to encrypt the root block device"
}

variable "root_block_device_volume_size" {
  type        = number
  default     = 8
  description = "The volume size (in GiB) to provision for the root block device. It cannot be smaller than the AMI it refers to."
}

variable "metadata_http_endpoint_enabled" {
  type        = bool
  default     = true
  description = "Whether the metadata service is available"
}

variable "metadata_http_put_response_hop_limit" {
  type        = number
  default     = 1
  description = "The desired HTTP PUT response hop limit (between 1 and 64) for instance metadata requests."
}

variable "metadata_http_tokens_required" {
  type        = bool
  default     = false
  description = "Whether or not the metadata service requires session tokens, also referred to as Instance Metadata Service Version 2."
}

variable "associate_public_ip_address" {
  type        = bool
  default     = false
  description = "Whether to associate public IP to the instance."
}

variable "ami" {
  type        = string
  description = "AMI ID to use for the bastion host"
  default     = null
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to use for the bastion host"
}

variable "cluster_sops_policy_arn" {
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  description = "ARN of the SOPS policy to attach to the bastion role"
}

variable "add_sops_policy" {
  description = "value of the policy arn for the cluster sops policy"
  type = bool
  default = true
}

variable "security_group_enabled" {
  type        = bool
  default     = false
  description = "Whether to create a security group for the bastion host"
}

variable "instance_profile" {
  type        = string
  default     = ""
  description = "IAM instance profile to attach to the bastion host"
}