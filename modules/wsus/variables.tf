variable "aws_profile" {
  description = "Profile to use for authentication with AWS"
  type        = string
}

variable "aws_region" {
  description = "AWS region to be used for deployment"
  type        = string
}
#wsus server specification

variable "ami" {
  type    = string
  default = "ami-003666d32869fa0d3"
}
variable "instance_type" {
  type    = string
  default = "m5.xlarge"
}

#wsus enabled products
variable "enabled_products" {
  type    = string
  default = "windows server 2008*,windows server 2012*,windows server 2016*,windows server 2019*"
}

#wsus disabled products
variable "disabled_products" {
  type    = string
  default = "*language packs*,*drivers*"
}

#wsus language
variable "language" {
  type    = string
  default = "en"
}

#wsus root drive size (GB)
variable "root_volume_size" {
  type    = number
  default = 75
}

#wsus root drive type
variable "root_volume_type" {
  type    = string
  default = "gp2"
}

# Extra volumes for data storage
variable "extra_ebs_blocks" {
  type = list(object({
    device_name = string
    volume_size = number
    volume_type = string
  }))
  default = [
    {
      # D:\ for WSUS storage
      device_name = "xvdf"
      volume_size = 400
      volume_type = "gp2"
    }
  ]
}

#wsus classifications - at least on must be set to 1

variable "critical_update" {
  default = "1"
}

variable "definition_updates" {
  default = "1"
}

variable "feature_packs" {
  default = "0"
}

variable "security_updates" {
  default = "1"
}

variable "service_packs" {
  default = "0"
}

variable "update_rollups" {
  default = "0"
}

variable "updates" {
  default = "1"
}

variable "drivers" {
  default = "0"
}

variable "driver_sets" {
  default = "0"
}

variable "tools" {
  default = "0"
}

variable "upgrades" {
  default = "0"
}

# WSUS targeting mode
# Client = use GPO
# Server = manually assign
variable "targeting_mode" {
  type    = string
  default = "Server"
}

#environmentals

variable "envname" {
  type    = string
  default = "DEV"
}

variable "envtype" {
  type = string
}

variable "subnet_id" {
  type    = string
  default = "subnet-0df49a358784309d8"
}

variable "key_name" {
  type    = string
  default = "p1cnap"
}

variable "customer" {
  type    = string
  default = "CNAP"
}

variable "vpc_id" {
  type    = string
  default = "vpc-067376be5c597ae82"
}

variable "vpc_security_group_ids" {
  #type = list(string)
  type    = string
  default = "sg-0280c0fcc12b630c2"
}

variable "timezone" {
  type    = string
  default = "GMT Standard Time"
}

variable "sg_name_overide" {
  type    = string
  default = ""
}

variable "wu_inbound_cidrs" {
  type    = list(string)
  default = ["10.122.0.0/16"]
}

#domain join vars

variable "region" {
  type    = string
  default = "us-gov-west-1"
}

variable "ad_domain_user" {
  type    = string
  default = "admin"
}

variable "ad_domain_user_password" {
  type    = string
  default = ""
}

variable "ad_password_secret_name" {
  description = "Optional. Name of secrets manager secret containing domain user password. Will override 'ad_domain_user_password' if set"
  type        = string
  default     = ""
}

variable "dns_servers" {
  type    = list(string)
  default = ["10.122.20.24,10.122.20.58"]
}

variable "local_password" {
  type    = string
  default = ""
}

variable "ad_domain_name" {
  type    = string
  default = "cnap.dso.mil"
}

variable "userdata" {
  type    = string
  default = ""
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}

variable "instance_profile" {
  type    = string
  default = "p1-citrix-ad-server-profile"
}
