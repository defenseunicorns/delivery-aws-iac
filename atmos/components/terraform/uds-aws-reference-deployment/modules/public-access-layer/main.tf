// These resources simulate a mission hero's environment to grant access to the eks cluster via
// A public facing VPC, load balancers, and a transit gateway


locals {
  public_lb_properties = {
    admin_gateway = {
      dns_name = module.admin_gateway_nlb.dns_name
    }
    tenant_gateway = {
      dns_name = module.tenant_gateway_nlb.dns_name
    }
  }
}

######################
# --- Public VPC --- #
######################
module "public_vpc" {
  source = "git::https://github.com/defenseunicorns/terraform-aws-uds-vpc.git?ref=v0.1.4"
  deployment_requirements = merge(var.public_access_layer_requirements.deployment_requirements, {
    stage = "public-demo"
  })
  vpc_options = {
    cidr = "10.1.0.0/22" // Private VPC uses "10.0.0.0/22, to use TGW, they cannot overlap
  }
  vpc_requirements = { azs = var.public_access_layer_requirements.azs }
}

##############################
# --- Public NLB - Admin --- #
##############################

module "admin_gateway_nlb" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-alb.git?ref=v9.12.0"

  name = "uds-admin-gateway-nlb-${var.public_access_layer_requirements.deployment_requirements.deploy_id}"

  enable_deletion_protection                                   = false
  enforce_security_group_inbound_rules_on_private_link_traffic = "on"
  load_balancer_type                                           = "network"
  subnets                                                      = module.public_vpc.vpc_properties.public_subnets
  vpc_id                                                       = module.public_vpc.vpc_properties.vpc_id

  security_group_ingress_rules = {
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  listeners = {
    ex-tcp-udp = {
      port     = 443
      protocol = "TCP"
      forward = {
        target_group_key = "admin_target_group"
      }
    }
  }
  target_groups = {
    admin_target_group = {
      availability_zone  = "all"
      name_prefix        = "admngw"
      port               = 443
      preserve_client_ip = false
      protocol           = "TCP"
      target_id          = var.public_access_layer_requirements.private_vpc_properties.reserved_ips_by_service.istio_admin_gateway[0].reserved_ip
      target_type        = "ip"
    }
  }
  additional_target_group_attachments = {
    admin_target_group_attachment2 = {
      availability_zone = "all"
      target_group_key  = "admin_target_group"
      target_type       = "ip"
      target_id         = var.public_access_layer_requirements.private_vpc_properties.reserved_ips_by_service.istio_admin_gateway[1].reserved_ip
      port              = "443"
    }
    admin_target_group_attachment3 = {
      availability_zone = "all"
      target_group_key  = "admin_target_group"
      target_type       = "ip"
      target_id         = var.public_access_layer_requirements.private_vpc_properties.reserved_ips_by_service.istio_admin_gateway[2].reserved_ip
      port              = "443"
    }
  }
}

###############################
# --- Public NLB - Tenant --- #
###############################

module "tenant_gateway_nlb" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-alb.git?ref=v9.12.0"

  name = "uds-tenant-gateway-nlb-${var.public_access_layer_requirements.deployment_requirements.deploy_id}"

  enable_deletion_protection                                   = false
  enforce_security_group_inbound_rules_on_private_link_traffic = "on"
  load_balancer_type                                           = "network"
  subnets                                                      = module.public_vpc.vpc_properties.public_subnets
  vpc_id                                                       = module.public_vpc.vpc_properties.vpc_id

  security_group_ingress_rules = {
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  listeners = {
    ex-tcp-udp = {
      port     = 443
      protocol = "TCP"
      forward = {
        target_group_key = "tenant_target_group"
      }
    }
  }
  target_groups = {
    tenant_target_group = {
      availability_zone  = "all"
      name_prefix        = "tntgw"
      port               = 443
      preserve_client_ip = false
      protocol           = "TCP"
      target_id          = var.public_access_layer_requirements.private_vpc_properties.reserved_ips_by_service.istio_tenant_gateway[0].reserved_ip
      target_type        = "ip"
    }
  }
  additional_target_group_attachments = {
    tenant_target_group_attachment2 = {
      availability_zone = "all"
      target_group_key  = "tenant_target_group"
      target_type       = "ip"
      target_id         = var.public_access_layer_requirements.private_vpc_properties.reserved_ips_by_service.istio_tenant_gateway[1].reserved_ip
      port              = "443"
    }
    tenant_target_group_attachment3 = {
      availability_zone = "all"
      target_group_key  = "tenant_target_group"
      target_type       = "ip"
      target_id         = var.public_access_layer_requirements.private_vpc_properties.reserved_ips_by_service.istio_tenant_gateway[2].reserved_ip
      port              = "443"
    }
  }
}

###########################
# --- Transit Gateway --- #
###########################

module "tgw_label" {
  source      = "cloudposse/label/null"
  version     = "v0.25.0"
  namespace   = "uds"
  stage       = var.public_access_layer_requirements.deployment_requirements.stage
  tenant      = var.public_access_layer_requirements.deployment_requirements.deploy_id
  name        = "tgw"
  delimiter   = "-"
  label_order = ["namespace", "name", "stage", "tenant"]

  tags = {
    PermissionsBoundary = split("/", var.public_access_layer_requirements.deployment_requirements.permissions_boundary_policy_arn)[1]
    DeployId            = var.public_access_layer_requirements.deployment_requirements.deploy_id
    Stage               = var.public_access_layer_requirements.deployment_requirements.stage
  }
}

resource "aws_ec2_transit_gateway" "tgw" {
  tags = merge(module.tgw_label.tags, { Name = module.tgw_label.id })
}

# Attachments for Public VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "public_attachment" {
  subnet_ids         = module.public_vpc.vpc_properties.private_subnets
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = module.public_vpc.vpc_properties.vpc_id
  tags               = module.tgw_label.tags
}

# Attachments for Private VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "private_attachment" {
  subnet_ids         = var.public_access_layer_requirements.private_vpc_properties.private_subnets
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = var.public_access_layer_requirements.private_vpc_properties.vpc_id
  tags               = module.tgw_label.tags
}

resource "aws_ec2_transit_gateway_route" "catch_all_to_public" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.public_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw.association_default_route_table_id
}

#### VPC Routes ####
# Public VPC Private Route Table
data "aws_route_table" "public_private_vpc_route_table" {
  vpc_id = module.public_vpc.vpc_properties.vpc_id
  filter {
    name   = "association.subnet-id"
    values = [module.public_vpc.vpc_properties.private_subnets[0]] //the same route table for all subnets
  }
}
resource "aws_route" "public_private_to_private_via_tgw" {
  route_table_id         = data.aws_route_table.public_private_vpc_route_table.id
  destination_cidr_block = var.public_access_layer_requirements.private_vpc_properties.vpc_cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Public VPC Public Route Table
data "aws_route_table" "public_public_vpc_route_table" {
  vpc_id = module.public_vpc.vpc_properties.vpc_id
  filter {
    name   = "association.subnet-id"
    values = [module.public_vpc.vpc_properties.public_subnets[0]] //the same route table for all subnets
  }
}
resource "aws_route" "public_public_to_private_via_tgw" {
  route_table_id         = data.aws_route_table.public_public_vpc_route_table.id
  destination_cidr_block = var.public_access_layer_requirements.private_vpc_properties.vpc_cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Private VPC Private Route Tables
data "aws_route_tables" "private_private_vpc_route_tables" {
  vpc_id = var.public_access_layer_requirements.private_vpc_properties.vpc_id
  filter {
    name   = "association.subnet-id"
    values = var.public_access_layer_requirements.private_vpc_properties.private_subnets
  }
}
resource "aws_route" "private_private_to_public_via_tgw" {
  count                  = 3
  route_table_id         = tolist(data.aws_route_tables.private_private_vpc_route_tables.ids)[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}
