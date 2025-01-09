//Outputs at mission-init reflect what needs to be decided at start-of-mission
// - this can be in a tofu root module that connects our opinionated wrappers for vpc, eks, bastion or at the componet level using atmos.
output "deployment_requirements" {
  value = {
    deploy_id                       = var.deploy_id,
    stage                           = var.stage,
    permissions_boundary_policy_arn = var.permissions_boundary_policy_arn
    impact_level                    = var.impact_level
  }
}

output "amis" {
  value = {
    for key, ami in data.aws_ami.init : key => { id = ami.id }
  }
}

output "aws_caller_identity" {
  value = data.aws_caller_identity.current
}

output "aws_partition" {
  value = data.aws_partition.current.partition
}

output "azs" {
  value = slice(data.aws_availability_zones.available.names, 0, 3)
}

output "region" {
  value = data.aws_region.current.name
}
