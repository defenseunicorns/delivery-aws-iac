output "public_vpc_properties" {
  value = module.public_vpc.vpc_properties
}


output "public_lb_properties" {
  value = local.public_lb_properties
}
