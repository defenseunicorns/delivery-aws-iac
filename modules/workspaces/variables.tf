variable "aws_profile" {
  description = "Optional provider that can be used with the AWS provider"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-gov-west-1"
}

variable "directory_id" {
  description = "ID of the AWS Directory service workspaces will use for authentication"
  type        = string
}

variable "ws_config" {
  description = "List of configurations for an arbitrary number of workspace instances"
  type = map(object({
    bundle_id                                 = string
    user_name                                 = string
    compute_type_name                         = string
    user_volume_size_gib                      = number
    root_volume_size_gib                      = number
    running_mode                              = string
    running_mode_auto_stop_timeout_in_minutes = number
  }))
  validation {
    condition = alltrue([
    for o in var.ws_config : can(regex("^VALUE$|^STANDARD$|^PERFORMANCE$|^POWER$|^GRAPHICS$|^POWERPRO$|^GRAPHICSPRO$", o.compute_type_name))])
    error_message = "Invalid compute type."
  }
  validation {
    condition = alltrue([
    for o in var.ws_config : can(regex("^AUTO_STOP$|^ALWAYS_ON$", o.running_mode))])
    error_message = "Invalid running mode."
  }
}

variable "common_tags" {
  description = "List of tags to add to every workspace"
  type        = map(string)
  default = {
    managed_by = "terraform"
  }
}