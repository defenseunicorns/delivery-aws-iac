variable "function_name" {
  description = "Name of lambda function"
  type        = string
  default     = ""
}

variable "function_description" {
  description = "Description of what the lambda function does"
  type        = string
  default     = ""
}

variable "function_handler" {
  description = "Method in function code that processes events"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "lambda_runtime" {
  description = "lambda function runtime (eg python3.8)"
  type        = string
  default     = "python3.9"
}

variable "timeout" {
  description = "Time before function times out in seconds"
  type        = number
  default     = 900
}

variable "output_path" {
  description = "Path of output zip file for function"
  type        = string
  default     = ""
}


variable "policy_statements" {
  type = map(object({
    effect     = string
    actions    = list(string)
    resources  = list(string)
    conditions = optional(map(string))
  }))
  default = {
    placeholder = {
      effect    = "Allow",
      actions   = [""],
      resources = [""]
    }
  }
}
