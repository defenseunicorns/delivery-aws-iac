variable "password_function_name" {
  description = "Name of lambda function"
  type        = string
  default     = "lambda_password_function"
}

variable "password_function_description" {
  description = "Description of what the lambda function does"
  type        = string
  default     = ""
}

variable "password_function_handler" {
  description = "Method in function code that processes events"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "password_lambda_runtime" {
  description = "lambda function runtime (eg python3.8)"
  type        = string
  default     = "python3.9"
}

variable "timeout" {
  description = "Time before function times out in seconds"
  type        = number
  default     = 900
}

variable "password_function_output_path" {
  description = "Path of output zip file for password rotation function"
  type        = string
  default     = "fixtures/functions/password_rotation.zip"
}

variable "password_function_source_path" {
  description = "Path of source file for password function"
  type = string
  default = ""
}

variable "enable_password_rotation_lambda" {
  description = "This will enable password rotation for your select users on your selected ec2 instances."
  type = bool
  default = false
}
variable "users" {
  description = "List of users to change passwords for password lambda function"
  type = list(string)
}

variable "instance_ids" {
  description = "List of instances that passwords will be rotated by lambda function"
  type = list(string)
}

variable "region" {
  description = "AWS Region"
  type        = string
  // TODO: Evaluate whether "" is ever a valid value for this variable. Does this need to be a required variable with a validation that checks against a list of known regions?
}

variable "name_prefix" {
  description = "Name prefix for all resources that use a randomized suffix"
  type        = string
  validation {
    condition     = length(var.name_prefix) <= 37
    error_message = "Name Prefix may not be longer than 37 characters."
  }
  default = ""
}