locals {
  deployment_properties = merge(module.mission_init.deployment_requirements, {
    region                       = module.mission_init.region
    eks_properties               = module.uds_eks.eks_properties
    private_vpc_properties       = module.private_vpc.vpc_properties
    bastion_properties           = module.bastion.bastion_properties
    bastion_ssh_config           = local_file.bastion_ssh_config.content
    bastion_ssh_config_file      = local_file.bastion_ssh_config.filename
    bastion_private_ssh_key      = local_file.bastion_private_key.content
    bastion_private_ssh_key_file = local_file.bastion_private_key.filename
    bastion_name                 = module.bastion_label.id
    public_lb_properties         = module.public_access_layer.public_lb_properties
  })
}

resource "local_file" "deployment_properties" {
  content  = jsonencode(local.deployment_properties)
  filename = "./ignore/deployment_properties.json"

}
output "deployment_properties" {
  sensitive = true
  value     = local.deployment_properties
}
output "deployment_properties_file" {
  sensitive = true
  value     = local.deployment_properties
}
