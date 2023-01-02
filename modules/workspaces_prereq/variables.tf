variable "aws_profile" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "ad_connector_name" {
  type        = string
  description = "The fully qualified name for the directory, such as corp.example.com"
}

variable "ad_secret_name" {
  type        = string
  description = "Name of a secret in secretsmanager that contains the username and password for AD"
}

variable "ad_connector_size" {
  type        = string
  description = "The size of the directory (Small or Large are accepted values)"
  default     = "Large"
}

variable "ad_connector_customer_dns_ips" {
  type        = list(string)
  description = "The DNS IP addresses of the domain to connect to"
}

variable "ad_connector_subnet_ids" {
  type        = list(string)
  description = "The identifiers of the subnets for the directory servers (2 subnets in 2 different AZs)"
}

variable "ad_connector_vpc_id" {
  type        = string
  description = "The identifier of the VPC that the directory is in"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The identifiers of the subnets where the directory resides"
}

variable "change_compute_type" {
  type        = bool
  description = "Whether WorkSpaces directory users can change the compute type (bundle) for their workspace"
  default     = false
}

variable "increase_volume_size" {
  type        = bool
  description = "Whether WorkSpaces directory users can increase the volume size of the drives on their workspace"
  default     = false
}

variable "rebuild_workspace" {
  type        = bool
  description = "Whether WorkSpaces directory users can rebuild the operating system of a workspace to its original state"
  default     = false
}

variable "restart_workspace" {
  type        = bool
  description = "Whether WorkSpaces directory users can restart their workspace"
  default     = true
}

variable "switch_running_mode" {
  type        = bool
  description = "Whether WorkSpaces directory users can switch the running mode of their workspace"
  default     = false
}

variable "setup_dod_ca" {
  type        = bool
  description = "Whether to register the DoD CAs with the AD connector using a local exec operation. Note, assumes bash as interpreter"
  default     = false
}

variable "default_ou" {
  description = "Default OU to place new workspaces in"
  type        = string
}

variable "enable_internet_access" {
  description = "This will allow outbound Internet access from your WorkSpaces when using an Internet Gateway. Leave disabled if you are using a Network Address Translation (NAT) configuration"
  type        = bool
  default     = false
}

variable "custom_security_group_id" {
  description = "The identifier of your custom security group. Should relate to the same VPC, where workspaces reside in."
  type        = string
  default     = ""
}