variable "public_access_layer_requirements" {
  type = object({
    azs                     = list(string)
    deployment_requirements = any
    private_vpc_properties  = any
    vpc_requirements        = any
  })
}
