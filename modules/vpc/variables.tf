variable "region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "name" {
  description = "Name to be used on all resources as identifier"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones to deploy into"
  type        = list(string)
}

variable private_subnet_tags {
  description = "Tags to apply to private subnets"
  type        = map(string)
  default     = {}
}

variable public_subnet_tags {
  description = "Tags to apply to public subnets"
  type        = map(string)
  default     = {}
}

variable "database_subnets" {
  description = "List of database subnets"
  type        = list(string)
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