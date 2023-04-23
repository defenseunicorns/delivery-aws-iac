variable "region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "name" {
  description = "Name to be used on all resources as identifier"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones to deploy into"
  type        = list(string)
}

variable "private_subnet_tags" {
  description = "Tags to apply to private subnets"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Tags to apply to public subnets"
  type        = map(string)
  default     = {}
}

variable "create_database_subnet_group" {
  description = "Create database subnet group"
  type        = bool
  default     = true
}

variable "create_database_subnet_route_table" {
  description = "Create database subnet route table"
  type        = bool
  default     = true
}

variable "instance_tenancy" {
  description = <<-EOD
  Tenancy of instances launched into the VPC.
  Valid values are "default" or "dedicated".
  EKS does not support dedicated tenancy.
  EOD
  type        = string
  default     = "default"
  validation {
    condition     = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "Value must be either default or dedicated."
  }
}

variable "public_subnets" {
  description = "List of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "List of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "database_subnets" {
  description = "List of database subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "intra_subnets" {
  description = "List of intra subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "intra_subnet_tags" {
  description = "Tags to apply to intra subnets"
  type        = map(string)
  default     = {}
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway for all private subnets"
  type        = bool
  default     = true
}

variable "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks for the VPC"
  type        = list(string)
  default     = []
}
