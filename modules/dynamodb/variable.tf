variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}
variable "billing_mode" {
  description = "A choice beetween billing mode: PAY_PER_REQUEST or PROVISIONED"
  type = string
  default = {}
  
}