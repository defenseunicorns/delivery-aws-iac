terraform {
  required_providers {
    context = {
      source  = "registry.terraform.io/cloudposse/context"
      version = "~> 0.4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34"
    }
  }

}
data "context_config" "this" {}
data "context_label" "this" {}
data "context_tags" "this" {}

data "aws_region" "current" {}

locals {
  iam_role_permissions_boundary_arn  = lookup(data.context_config.this.values, "permissions_boundary_policy_arn", null)  //TODO: add context for tag based IAM permissions boundaries
  iam_role_permissions_boundary_name = lookup(data.context_config.this.values, "permissions_boundary_policy_name", null) //TODO: add context for tag based IAM permissions boundaries

  default_vpc_config = {
    amazon_side_asn                                                   = "64512"
    azs                                                               = []
    cidr                                                              = "10.0.0.0/16"
    create_database_internet_gateway_route                            = false
    create_database_nat_gateway_route                                 = false
    create_database_subnet_group                                      = true
    create_database_subnet_route_table                                = false
    create_egress_only_igw                                            = true
    create_elasticache_subnet_group                                   = true
    create_elasticache_subnet_route_table                             = false
    create_flow_log_cloudwatch_iam_role                               = false
    create_flow_log_cloudwatch_log_group                              = false
    create_igw                                                        = true
    create_multiple_intra_route_tables                                = false
    create_multiple_public_route_tables                               = false
    create_redshift_subnet_group                                      = true
    create_redshift_subnet_route_table                                = false
    create_vpc                                                        = true
    customer_gateway_tags                                             = {}
    customer_gateways                                                 = {}
    customer_owned_ipv4_pool                                          = null
    database_acl_tags                                                 = {}
    database_dedicated_network_acl                                    = false
    database_inbound_acl_rules                                        = [{ "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_action" : "allow", "rule_number" : 100, "to_port" : 0 }]
    database_outbound_acl_rules                                       = [{ "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_action" : "allow", "rule_number" : 100, "to_port" : 0 }]
    database_route_table_tags                                         = {}
    database_subnet_assign_ipv6_address_on_creation                   = false
    database_subnet_enable_dns64                                      = true
    database_subnet_enable_resource_name_dns_a_record_on_launch       = false
    database_subnet_enable_resource_name_dns_aaaa_record_on_launch    = true
    database_subnet_group_name                                        = null
    database_subnet_group_tags                                        = {}
    database_subnet_ipv6_native                                       = false
    database_subnet_ipv6_prefixes                                     = []
    database_subnet_names                                             = []
    database_subnet_private_dns_hostname_type_on_launch               = null
    database_subnet_suffix                                            = "db"
    database_subnet_tags                                              = {}
    database_subnets                                                  = []
    default_network_acl_egress                                        = [{ "action" : "allow", "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_no" : 100, "to_port" : 0 }, { "action" : "allow", "from_port" : 0, "ipv6_cidr_block" : "::/0", "protocol" : "-1", "rule_no" : 101, "to_port" : 0 }]
    default_network_acl_ingress                                       = [{ "action" : "allow", "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_no" : 100, "to_port" : 0 }, { "action" : "allow", "from_port" : 0, "ipv6_cidr_block" : "::/0", "protocol" : "-1", "rule_no" : 101, "to_port" : 0 }]
    default_network_acl_name                                          = null
    default_network_acl_tags                                          = {}
    default_route_table_name                                          = null
    default_route_table_propagating_vgws                              = []
    default_route_table_routes                                        = []
    default_route_table_tags                                          = {}
    default_security_group_egress                                     = []
    default_security_group_ingress                                    = []
    default_security_group_name                                       = null
    default_security_group_tags                                       = {}
    default_vpc_enable_dns_hostnames                                  = true
    default_vpc_enable_dns_support                                    = true
    default_vpc_name                                                  = null
    default_vpc_tags                                                  = {}
    dhcp_options_domain_name                                          = ""
    dhcp_options_domain_name_servers                                  = ["AmazonProvidedDNS"]
    dhcp_options_ipv6_address_preferred_lease_time                    = null
    dhcp_options_netbios_name_servers                                 = []
    dhcp_options_netbios_node_type                                    = ""
    dhcp_options_ntp_servers                                          = []
    dhcp_options_tags                                                 = {}
    elasticache_acl_tags                                              = {}
    elasticache_dedicated_network_acl                                 = false
    elasticache_inbound_acl_rules                                     = [{ "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_action" : "allow", "rule_number" : 100, "to_port" : 0 }]
    elasticache_outbound_acl_rules                                    = [{ "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_action" : "allow", "rule_number" : 100, "to_port" : 0 }]
    elasticache_route_table_tags                                      = {}
    elasticache_subnet_assign_ipv6_address_on_creation                = false
    elasticache_subnet_enable_dns64                                   = true
    elasticache_subnet_enable_resource_name_dns_a_record_on_launch    = false
    elasticache_subnet_enable_resource_name_dns_aaaa_record_on_launch = true
    elasticache_subnet_group_name                                     = null
    elasticache_subnet_group_tags                                     = {}
    elasticache_subnet_ipv6_native                                    = false
    elasticache_subnet_ipv6_prefixes                                  = []
    elasticache_subnet_names                                          = []
    elasticache_subnet_private_dns_hostname_type_on_launch            = null
    elasticache_subnet_suffix                                         = "elasticache"
    elasticache_subnet_tags                                           = {}
    elasticache_subnets                                               = []
    enable_dhcp_options                                               = false
    enable_dns_hostnames                                              = true
    enable_dns_support                                                = true
    enable_flow_log                                                   = false
    enable_ipv6                                                       = false
    enable_nat_gateway                                                = false
    enable_network_address_usage_metrics                              = null
    enable_public_redshift                                            = false
    enable_vpn_gateway                                                = false
    external_nat_ip_ids                                               = []
    external_nat_ips                                                  = []
    flow_log_cloudwatch_iam_role_arn                                  = ""
    flow_log_cloudwatch_log_group_class                               = null
    flow_log_cloudwatch_log_group_kms_key_id                          = null
    flow_log_cloudwatch_log_group_name_prefix                         = "/aws/vpc-flow-log/"
    flow_log_cloudwatch_log_group_name_suffix                         = ""
    flow_log_cloudwatch_log_group_retention_in_days                   = null
    flow_log_cloudwatch_log_group_skip_destroy                        = false
    flow_log_deliver_cross_account_role                               = null
    flow_log_destination_arn                                          = ""
    flow_log_destination_type                                         = "cloud-watch-logs"
    flow_log_file_format                                              = null
    flow_log_hive_compatible_partitions                               = false
    flow_log_log_format                                               = null
    flow_log_max_aggregation_interval                                 = 600
    flow_log_per_hour_partition                                       = false
    flow_log_traffic_type                                             = "ALL"
    igw_tags                                                          = {}
    instance_tenancy                                                  = "default"
    intra_acl_tags                                                    = {}
    intra_dedicated_network_acl                                       = false
    intra_inbound_acl_rules                                           = [{ "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_action" : "allow", "rule_number" : 100, "to_port" : 0 }]
    intra_outbound_acl_rules                                          = [{ "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_action" : "allow", "rule_number" : 100, "to_port" : 0 }]
    intra_route_table_tags                                            = {}
    intra_subnet_assign_ipv6_address_on_creation                      = false
    intra_subnet_enable_dns64                                         = true
    intra_subnet_enable_resource_name_dns_a_record_on_launch          = false
    intra_subnet_enable_resource_name_dns_aaaa_record_on_launch       = true
    intra_subnet_ipv6_native                                          = false
    intra_subnet_ipv6_prefixes                                        = []
    intra_subnet_names                                                = []
    intra_subnet_private_dns_hostname_type_on_launch                  = null
    intra_subnet_suffix                                               = "intra"
    intra_subnet_tags                                                 = {}
    intra_subnets                                                     = []
    ipv4_ipam_pool_id                                                 = null
    ipv4_netmask_length                                               = null
    ipv6_cidr                                                         = null
    ipv6_cidr_block_network_border_group                              = null
    ipv6_ipam_pool_id                                                 = null
    ipv6_netmask_length                                               = null
    manage_default_network_acl                                        = true
    manage_default_route_table                                        = true
    manage_default_security_group                                     = true
    manage_default_vpc                                                = false
    map_customer_owned_ip_on_launch                                   = false
    map_public_ip_on_launch                                           = false
    name                                                              = ""
    nat_eip_tags                                                      = {}
    nat_gateway_destination_cidr_block                                = "0.0.0.0/0"
    nat_gateway_tags                                                  = {}
    one_nat_gateway_per_az                                            = false
    outpost_acl_tags                                                  = {}
    outpost_arn                                                       = null
    outpost_az                                                        = null
    outpost_dedicated_network_acl                                     = false
    outpost_inbound_acl_rules                                         = [{ "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_action" : "allow", "rule_number" : 100, "to_port" : 0 }]
    outpost_outbound_acl_rules                                        = [{ "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_action" : "allow", "rule_number" : 100, "to_port" : 0 }]
    outpost_subnet_assign_ipv6_address_on_creation                    = false
    outpost_subnet_enable_dns64                                       = true
    outpost_subnet_enable_resource_name_dns_a_record_on_launch        = false
    outpost_subnet_enable_resource_name_dns_aaaa_record_on_launch     = true
    outpost_subnet_ipv6_native                                        = false
    outpost_subnet_ipv6_prefixes                                      = []
    outpost_subnet_names                                              = []
    outpost_subnet_private_dns_hostname_type_on_launch                = null
    outpost_subnet_suffix                                             = "outpost"
    outpost_subnet_tags                                               = {}
    outpost_subnets                                                   = []
    private_acl_tags                                                  = {}
    private_dedicated_network_acl                                     = false
    private_inbound_acl_rules                                         = [{ "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_action" : "allow", "rule_number" : 100, "to_port" : 0 }]
    private_outbound_acl_rules                                        = [{ "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_action" : "allow", "rule_number" : 100, "to_port" : 0 }]
    private_route_table_tags                                          = {}
    private_subnet_assign_ipv6_address_on_creation                    = false
    private_subnet_enable_dns64                                       = true
    private_subnet_enable_resource_name_dns_a_record_on_launch        = false
    private_subnet_enable_resource_name_dns_aaaa_record_on_launch     = true
    private_subnet_ipv6_native                                        = false
    private_subnet_ipv6_prefixes                                      = []
    private_subnet_names                                              = []
    private_subnet_private_dns_hostname_type_on_launch                = null
    private_subnet_suffix                                             = "private"
    private_subnet_tags                                               = {}
    private_subnet_tags_per_az                                        = {}
    private_subnets                                                   = []
    propagate_intra_route_tables_vgw                                  = false
    propagate_private_route_tables_vgw                                = false
    propagate_public_route_tables_vgw                                 = false
    public_acl_tags                                                   = {}
    public_dedicated_network_acl                                      = false
    public_inbound_acl_rules                                          = [{ "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_action" : "allow", "rule_number" : 100, "to_port" : 0 }]
    public_outbound_acl_rules                                         = [{ "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_action" : "allow", "rule_number" : 100, "to_port" : 0 }]
    public_route_table_tags                                           = {}
    public_subnet_assign_ipv6_address_on_creation                     = false
    public_subnet_enable_dns64                                        = true
    public_subnet_enable_resource_name_dns_a_record_on_launch         = false
    public_subnet_enable_resource_name_dns_aaaa_record_on_launch      = true
    public_subnet_ipv6_native                                         = false
    public_subnet_ipv6_prefixes                                       = []
    public_subnet_names                                               = []
    public_subnet_private_dns_hostname_type_on_launch                 = null
    public_subnet_suffix                                              = "public"
    public_subnet_tags                                                = {}
    public_subnet_tags_per_az                                         = {}
    public_subnets                                                    = []
    putin_khuylo                                                      = true
    redshift_acl_tags                                                 = {}
    redshift_dedicated_network_acl                                    = false
    redshift_inbound_acl_rules                                        = [{ "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_action" : "allow", "rule_number" : 100, "to_port" : 0 }]
    redshift_outbound_acl_rules                                       = [{ "cidr_block" : "0.0.0.0/0", "from_port" : 0, "protocol" : "-1", "rule_action" : "allow", "rule_number" : 100, "to_port" : 0 }]
    redshift_route_table_tags                                         = {}
    redshift_subnet_assign_ipv6_address_on_creation                   = false
    redshift_subnet_enable_dns64                                      = true
    redshift_subnet_enable_resource_name_dns_a_record_on_launch       = false
    redshift_subnet_enable_resource_name_dns_aaaa_record_on_launch    = true
    redshift_subnet_group_name                                        = null
    redshift_subnet_group_tags                                        = {}
    redshift_subnet_ipv6_native                                       = false
    redshift_subnet_ipv6_prefixes                                     = []
    redshift_subnet_names                                             = []
    redshift_subnet_private_dns_hostname_type_on_launch               = null
    redshift_subnet_suffix                                            = "redshift"
    redshift_subnet_tags                                              = {}
    redshift_subnets                                                  = []
    reuse_nat_ips                                                     = false
    secondary_cidr_blocks                                             = []
    single_nat_gateway                                                = false
    tags                                                              = {}
    use_ipam_pool                                                     = false
    vpc_flow_log_iam_policy_name                                      = "vpc-flow-log-to-cloudwatch"
    vpc_flow_log_iam_policy_use_name_prefix                           = true
    vpc_flow_log_iam_role_name                                        = "vpc-flow-log-role"
    vpc_flow_log_iam_role_use_name_prefix                             = true
    vpc_flow_log_permissions_boundary                                 = null
    vpc_flow_log_tags                                                 = {}
    vpc_tags                                                          = {}
    vpn_gateway_az                                                    = null
    vpn_gateway_id                                                    = ""
    vpn_gateway_tags                                                  = {}

  }
  base_vpc_config = {
    azs                               = var.required_vpc_vars.azs
    name                              = data.context_label.this.rendered
    create_database_subnet_group      = true
    instance_tenancy                  = var.optional_vpc_vars.instance_tenancy # TODO: group with flag
    vpc_flow_log_permissions_boundary = local.iam_role_permissions_boundary_arn
    private_subnet_tags = {
      "context"                                  = "${data.context_label.this.rendered}"
      "type"                                     = "private"
      "kubernetes.io/cluster/local.cluster_name" = "shared"
      "kubernetes.io/role/internal-elb"          = 1
    }
    public_subnet_tags = {
      "context" = "${data.context_label.this.rendered}"
      "type"    = "public"
    }
    secondary_cidr_blocks = var.required_vpc_vars.secondary_cidr_blocks
    tags = merge(data.context_tags.this.tags, {
      "context"             = "${data.context_label.this.rendered}"
      "PermissionsBoundary" = local.iam_role_permissions_boundary_name
    })
    cidr = var.required_vpc_vars.vpc_cidr
    # TODO: context
    # Manage so we can name
    manage_default_network_acl = true
    default_network_acl_tags   = { Name = "${data.context_label.this.rendered}-default" }

    manage_default_route_table = true
    default_route_table_tags   = { Name = "${data.context_label.this.rendered}-default" }

    manage_default_security_group = true
    default_security_group_tags   = { Name = "${data.context_label.this.rendered}-default" }

    public_subnets   = [for k, v in module.subnet_addrs.network_cidr_blocks : v if strcontains(k, "public")]
    private_subnets  = [for k, v in module.subnet_addrs.network_cidr_blocks : v if strcontains(k, "private")]
    database_subnets = [for k, v in module.subnet_addrs.network_cidr_blocks : v if strcontains(k, "database")]

    # TODO: move away from single
    # TODO: Context flag
    single_nat_gateway = true #remove if in a private VPC behind TGW
    enable_nat_gateway = true #remove if in a private VPC behind TGW

    # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
    enable_flow_log                                 = true
    flow_log_cloudwatch_log_group_retention_in_days = 365
    vpc_flow_log_permissions_boundary               = local.iam_role_permissions_boundary_arn
    create_flow_log_cloudwatch_log_group            = true
    create_flow_log_cloudwatch_iam_role             = true
    flow_log_max_aggregation_interval               = 60
  }
  vpc_config = merge(local.default_vpc_config, local.base_vpc_config)
}


#############
# Variables #
############## Required
variable "required_vpc_vars" {
  description = <<-EOD
  These values are required to be set for the module to function
  For vpc_subnets, see https://github.com/hashicorp/terraform-cidr-subnets
  EOD
  type = object({
    azs                   = list(string)
    vpc_cidr              = string
    secondary_cidr_blocks = list(string)
    vpc_subnets = list(object({
      name     = string
      new_bits = number
      }

    ))
  })
}

# Optional
variable "optional_vpc_vars" {
  description = "This variable can be set to give flexability on the deployment"
  type = object({
    create_default_vpc_endpoints   = optional(string, false)
    instance_tenancy               = optional(string, false)
    vpc_exclude_availability_zones = optional(list(string))
  })
  validation {
    condition     = contains(["default", "dedicated"], var.optional_vpc_vars.instance_tenancy)
    error_message = "Value must be either default or dedicated."
  }
  default = {}
}

# Modules
//TODO: Should subnet definition and managment happen at mission-init time?
module "subnet_addrs" {
  source = "git::https://github.com/hashicorp/terraform-cidr-subnets?ref=v1.0.0"

  base_cidr_block = var.required_vpc_vars.vpc_cidr
  networks        = var.required_vpc_vars.vpc_subnets
}

module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.13.0"

  amazon_side_asn                                                   = local.vpc_config.amazon_side_asn
  azs                                                               = local.vpc_config.azs
  cidr                                                              = local.vpc_config.cidr
  create_database_internet_gateway_route                            = local.vpc_config.create_database_internet_gateway_route
  create_database_nat_gateway_route                                 = local.vpc_config.create_database_nat_gateway_route
  create_database_subnet_group                                      = local.vpc_config.create_database_subnet_group
  create_database_subnet_route_table                                = local.vpc_config.create_database_subnet_route_table
  create_egress_only_igw                                            = local.vpc_config.create_egress_only_igw
  create_elasticache_subnet_group                                   = local.vpc_config.create_elasticache_subnet_group
  create_elasticache_subnet_route_table                             = local.vpc_config.create_elasticache_subnet_route_table
  create_flow_log_cloudwatch_iam_role                               = local.vpc_config.create_flow_log_cloudwatch_iam_role
  create_flow_log_cloudwatch_log_group                              = local.vpc_config.create_flow_log_cloudwatch_log_group
  create_igw                                                        = local.vpc_config.create_igw
  create_multiple_intra_route_tables                                = local.vpc_config.create_multiple_intra_route_tables
  create_multiple_public_route_tables                               = local.vpc_config.create_multiple_public_route_tables
  create_redshift_subnet_group                                      = local.vpc_config.create_redshift_subnet_group
  create_redshift_subnet_route_table                                = local.vpc_config.create_redshift_subnet_route_table
  create_vpc                                                        = local.vpc_config.create_vpc
  customer_gateway_tags                                             = local.vpc_config.customer_gateway_tags
  customer_gateways                                                 = local.vpc_config.customer_gateways
  customer_owned_ipv4_pool                                          = local.vpc_config.customer_owned_ipv4_pool
  database_acl_tags                                                 = local.vpc_config.database_acl_tags
  database_dedicated_network_acl                                    = local.vpc_config.database_dedicated_network_acl
  database_inbound_acl_rules                                        = local.vpc_config.database_inbound_acl_rules
  database_outbound_acl_rules                                       = local.vpc_config.database_outbound_acl_rules
  database_route_table_tags                                         = local.vpc_config.database_route_table_tags
  database_subnet_assign_ipv6_address_on_creation                   = local.vpc_config.database_subnet_assign_ipv6_address_on_creation
  database_subnet_enable_dns64                                      = local.vpc_config.database_subnet_enable_dns64
  database_subnet_enable_resource_name_dns_a_record_on_launch       = local.vpc_config.database_subnet_enable_resource_name_dns_a_record_on_launch
  database_subnet_enable_resource_name_dns_aaaa_record_on_launch    = local.vpc_config.database_subnet_enable_resource_name_dns_aaaa_record_on_launch
  database_subnet_group_name                                        = local.vpc_config.database_subnet_group_name
  database_subnet_group_tags                                        = local.vpc_config.database_subnet_group_tags
  database_subnet_ipv6_native                                       = local.vpc_config.database_subnet_ipv6_native
  database_subnet_ipv6_prefixes                                     = local.vpc_config.database_subnet_ipv6_prefixes
  database_subnet_names                                             = local.vpc_config.database_subnet_names
  database_subnet_private_dns_hostname_type_on_launch               = local.vpc_config.database_subnet_private_dns_hostname_type_on_launch
  database_subnet_suffix                                            = local.vpc_config.database_subnet_suffix
  database_subnet_tags                                              = local.vpc_config.database_subnet_tags
  database_subnets                                                  = local.vpc_config.database_subnets
  default_network_acl_egress                                        = local.vpc_config.default_network_acl_egress
  default_network_acl_ingress                                       = local.vpc_config.default_network_acl_ingress
  default_network_acl_name                                          = local.vpc_config.default_network_acl_name
  default_network_acl_tags                                          = local.vpc_config.default_network_acl_tags
  default_route_table_name                                          = local.vpc_config.default_route_table_name
  default_route_table_propagating_vgws                              = local.vpc_config.default_route_table_propagating_vgws
  default_route_table_routes                                        = local.vpc_config.default_route_table_routes
  default_route_table_tags                                          = local.vpc_config.default_route_table_tags
  default_security_group_egress                                     = local.vpc_config.default_security_group_egress
  default_security_group_ingress                                    = local.vpc_config.default_security_group_ingress
  default_security_group_name                                       = local.vpc_config.default_security_group_name
  default_security_group_tags                                       = local.vpc_config.default_security_group_tags
  default_vpc_enable_dns_hostnames                                  = local.vpc_config.default_vpc_enable_dns_hostnames
  default_vpc_enable_dns_support                                    = local.vpc_config.default_vpc_enable_dns_support
  default_vpc_name                                                  = local.vpc_config.default_vpc_name
  default_vpc_tags                                                  = local.vpc_config.default_vpc_tags
  dhcp_options_domain_name                                          = local.vpc_config.dhcp_options_domain_name
  dhcp_options_domain_name_servers                                  = local.vpc_config.dhcp_options_domain_name_servers
  dhcp_options_ipv6_address_preferred_lease_time                    = local.vpc_config.dhcp_options_ipv6_address_preferred_lease_time
  dhcp_options_netbios_name_servers                                 = local.vpc_config.dhcp_options_netbios_name_servers
  dhcp_options_netbios_node_type                                    = local.vpc_config.dhcp_options_netbios_node_type
  dhcp_options_ntp_servers                                          = local.vpc_config.dhcp_options_ntp_servers
  dhcp_options_tags                                                 = local.vpc_config.dhcp_options_tags
  elasticache_acl_tags                                              = local.vpc_config.elasticache_acl_tags
  elasticache_dedicated_network_acl                                 = local.vpc_config.elasticache_dedicated_network_acl
  elasticache_inbound_acl_rules                                     = local.vpc_config.elasticache_inbound_acl_rules
  elasticache_outbound_acl_rules                                    = local.vpc_config.elasticache_outbound_acl_rules
  elasticache_route_table_tags                                      = local.vpc_config.elasticache_route_table_tags
  elasticache_subnet_assign_ipv6_address_on_creation                = local.vpc_config.elasticache_subnet_assign_ipv6_address_on_creation
  elasticache_subnet_enable_dns64                                   = local.vpc_config.elasticache_subnet_enable_dns64
  elasticache_subnet_enable_resource_name_dns_a_record_on_launch    = local.vpc_config.elasticache_subnet_enable_resource_name_dns_a_record_on_launch
  elasticache_subnet_enable_resource_name_dns_aaaa_record_on_launch = local.vpc_config.elasticache_subnet_enable_resource_name_dns_aaaa_record_on_launch
  elasticache_subnet_group_name                                     = local.vpc_config.elasticache_subnet_group_name
  elasticache_subnet_group_tags                                     = local.vpc_config.elasticache_subnet_group_tags
  elasticache_subnet_ipv6_native                                    = local.vpc_config.elasticache_subnet_ipv6_native
  elasticache_subnet_ipv6_prefixes                                  = local.vpc_config.elasticache_subnet_ipv6_prefixes
  elasticache_subnet_names                                          = local.vpc_config.elasticache_subnet_names
  elasticache_subnet_private_dns_hostname_type_on_launch            = local.vpc_config.elasticache_subnet_private_dns_hostname_type_on_launch
  elasticache_subnet_suffix                                         = local.vpc_config.elasticache_subnet_suffix
  elasticache_subnet_tags                                           = local.vpc_config.elasticache_subnet_tags
  elasticache_subnets                                               = local.vpc_config.elasticache_subnets
  enable_dhcp_options                                               = local.vpc_config.enable_dhcp_options
  enable_dns_hostnames                                              = local.vpc_config.enable_dns_hostnames
  enable_dns_support                                                = local.vpc_config.enable_dns_support
  enable_flow_log                                                   = local.vpc_config.enable_flow_log
  enable_ipv6                                                       = local.vpc_config.enable_ipv6
  enable_nat_gateway                                                = local.vpc_config.enable_nat_gateway
  enable_network_address_usage_metrics                              = local.vpc_config.enable_network_address_usage_metrics
  enable_public_redshift                                            = local.vpc_config.enable_public_redshift
  enable_vpn_gateway                                                = local.vpc_config.enable_vpn_gateway
  external_nat_ip_ids                                               = local.vpc_config.external_nat_ip_ids
  external_nat_ips                                                  = local.vpc_config.external_nat_ips
  flow_log_cloudwatch_iam_role_arn                                  = local.vpc_config.flow_log_cloudwatch_iam_role_arn
  flow_log_cloudwatch_log_group_class                               = local.vpc_config.flow_log_cloudwatch_log_group_class
  flow_log_cloudwatch_log_group_kms_key_id                          = local.vpc_config.flow_log_cloudwatch_log_group_kms_key_id
  flow_log_cloudwatch_log_group_name_prefix                         = local.vpc_config.flow_log_cloudwatch_log_group_name_prefix
  flow_log_cloudwatch_log_group_name_suffix                         = local.vpc_config.flow_log_cloudwatch_log_group_name_suffix
  flow_log_cloudwatch_log_group_retention_in_days                   = local.vpc_config.flow_log_cloudwatch_log_group_retention_in_days
  flow_log_cloudwatch_log_group_skip_destroy                        = local.vpc_config.flow_log_cloudwatch_log_group_skip_destroy
  flow_log_deliver_cross_account_role                               = local.vpc_config.flow_log_deliver_cross_account_role
  flow_log_destination_arn                                          = local.vpc_config.flow_log_destination_arn
  flow_log_destination_type                                         = local.vpc_config.flow_log_destination_type
  flow_log_file_format                                              = local.vpc_config.flow_log_file_format
  flow_log_hive_compatible_partitions                               = local.vpc_config.flow_log_hive_compatible_partitions
  flow_log_log_format                                               = local.vpc_config.flow_log_log_format
  flow_log_max_aggregation_interval                                 = local.vpc_config.flow_log_max_aggregation_interval
  flow_log_per_hour_partition                                       = local.vpc_config.flow_log_per_hour_partition
  flow_log_traffic_type                                             = local.vpc_config.flow_log_traffic_type
  igw_tags                                                          = local.vpc_config.igw_tags
  instance_tenancy                                                  = local.vpc_config.instance_tenancy
  intra_acl_tags                                                    = local.vpc_config.intra_acl_tags
  intra_dedicated_network_acl                                       = local.vpc_config.intra_dedicated_network_acl
  intra_inbound_acl_rules                                           = local.vpc_config.intra_inbound_acl_rules
  intra_outbound_acl_rules                                          = local.vpc_config.intra_outbound_acl_rules
  intra_route_table_tags                                            = local.vpc_config.intra_route_table_tags
  intra_subnet_assign_ipv6_address_on_creation                      = local.vpc_config.intra_subnet_assign_ipv6_address_on_creation
  intra_subnet_enable_dns64                                         = local.vpc_config.intra_subnet_enable_dns64
  intra_subnet_enable_resource_name_dns_a_record_on_launch          = local.vpc_config.intra_subnet_enable_resource_name_dns_a_record_on_launch
  intra_subnet_enable_resource_name_dns_aaaa_record_on_launch       = local.vpc_config.intra_subnet_enable_resource_name_dns_aaaa_record_on_launch
  intra_subnet_ipv6_native                                          = local.vpc_config.intra_subnet_ipv6_native
  intra_subnet_ipv6_prefixes                                        = local.vpc_config.intra_subnet_ipv6_prefixes
  intra_subnet_names                                                = local.vpc_config.intra_subnet_names
  intra_subnet_private_dns_hostname_type_on_launch                  = local.vpc_config.intra_subnet_private_dns_hostname_type_on_launch
  intra_subnet_suffix                                               = local.vpc_config.intra_subnet_suffix
  intra_subnet_tags                                                 = local.vpc_config.intra_subnet_tags
  intra_subnets                                                     = local.vpc_config.intra_subnets
  ipv4_ipam_pool_id                                                 = local.vpc_config.ipv4_ipam_pool_id
  ipv4_netmask_length                                               = local.vpc_config.ipv4_netmask_length
  ipv6_cidr                                                         = local.vpc_config.ipv6_cidr
  ipv6_cidr_block_network_border_group                              = local.vpc_config.ipv6_cidr_block_network_border_group
  ipv6_ipam_pool_id                                                 = local.vpc_config.ipv6_ipam_pool_id
  ipv6_netmask_length                                               = local.vpc_config.ipv6_netmask_length
  manage_default_network_acl                                        = local.vpc_config.manage_default_network_acl
  manage_default_route_table                                        = local.vpc_config.manage_default_route_table
  manage_default_security_group                                     = local.vpc_config.manage_default_security_group
  manage_default_vpc                                                = local.vpc_config.manage_default_vpc
  map_customer_owned_ip_on_launch                                   = local.vpc_config.map_customer_owned_ip_on_launch
  map_public_ip_on_launch                                           = local.vpc_config.map_public_ip_on_launch
  name                                                              = local.vpc_config.name
  nat_eip_tags                                                      = local.vpc_config.nat_eip_tags
  nat_gateway_destination_cidr_block                                = local.vpc_config.nat_gateway_destination_cidr_block
  nat_gateway_tags                                                  = local.vpc_config.nat_gateway_tags
  one_nat_gateway_per_az                                            = local.vpc_config.one_nat_gateway_per_az
  outpost_acl_tags                                                  = local.vpc_config.outpost_acl_tags
  outpost_arn                                                       = local.vpc_config.outpost_arn
  outpost_az                                                        = local.vpc_config.outpost_az
  outpost_dedicated_network_acl                                     = local.vpc_config.outpost_dedicated_network_acl
  outpost_inbound_acl_rules                                         = local.vpc_config.outpost_inbound_acl_rules
  outpost_outbound_acl_rules                                        = local.vpc_config.outpost_outbound_acl_rules
  outpost_subnet_assign_ipv6_address_on_creation                    = local.vpc_config.outpost_subnet_assign_ipv6_address_on_creation
  outpost_subnet_enable_dns64                                       = local.vpc_config.outpost_subnet_enable_dns64
  outpost_subnet_enable_resource_name_dns_a_record_on_launch        = local.vpc_config.outpost_subnet_enable_resource_name_dns_a_record_on_launch
  outpost_subnet_enable_resource_name_dns_aaaa_record_on_launch     = local.vpc_config.outpost_subnet_enable_resource_name_dns_aaaa_record_on_launch
  outpost_subnet_ipv6_native                                        = local.vpc_config.outpost_subnet_ipv6_native
  outpost_subnet_ipv6_prefixes                                      = local.vpc_config.outpost_subnet_ipv6_prefixes
  outpost_subnet_names                                              = local.vpc_config.outpost_subnet_names
  outpost_subnet_private_dns_hostname_type_on_launch                = local.vpc_config.outpost_subnet_private_dns_hostname_type_on_launch
  outpost_subnet_suffix                                             = local.vpc_config.outpost_subnet_suffix
  outpost_subnet_tags                                               = local.vpc_config.outpost_subnet_tags
  outpost_subnets                                                   = local.vpc_config.outpost_subnets
  private_acl_tags                                                  = local.vpc_config.private_acl_tags
  private_dedicated_network_acl                                     = local.vpc_config.private_dedicated_network_acl
  private_inbound_acl_rules                                         = local.vpc_config.private_inbound_acl_rules
  private_outbound_acl_rules                                        = local.vpc_config.private_outbound_acl_rules
  private_route_table_tags                                          = local.vpc_config.private_route_table_tags
  private_subnet_assign_ipv6_address_on_creation                    = local.vpc_config.private_subnet_assign_ipv6_address_on_creation
  private_subnet_enable_dns64                                       = local.vpc_config.private_subnet_enable_dns64
  private_subnet_enable_resource_name_dns_a_record_on_launch        = local.vpc_config.private_subnet_enable_resource_name_dns_a_record_on_launch
  private_subnet_enable_resource_name_dns_aaaa_record_on_launch     = local.vpc_config.private_subnet_enable_resource_name_dns_aaaa_record_on_launch
  private_subnet_ipv6_native                                        = local.vpc_config.private_subnet_ipv6_native
  private_subnet_ipv6_prefixes                                      = local.vpc_config.private_subnet_ipv6_prefixes
  private_subnet_names                                              = local.vpc_config.private_subnet_names
  private_subnet_private_dns_hostname_type_on_launch                = local.vpc_config.private_subnet_private_dns_hostname_type_on_launch
  private_subnet_suffix                                             = local.vpc_config.private_subnet_suffix
  private_subnet_tags                                               = local.vpc_config.private_subnet_tags
  private_subnet_tags_per_az                                        = local.vpc_config.private_subnet_tags_per_az
  private_subnets                                                   = local.vpc_config.private_subnets
  propagate_intra_route_tables_vgw                                  = local.vpc_config.propagate_intra_route_tables_vgw
  propagate_private_route_tables_vgw                                = local.vpc_config.propagate_private_route_tables_vgw
  propagate_public_route_tables_vgw                                 = local.vpc_config.propagate_public_route_tables_vgw
  public_acl_tags                                                   = local.vpc_config.public_acl_tags
  public_dedicated_network_acl                                      = local.vpc_config.public_dedicated_network_acl
  public_inbound_acl_rules                                          = local.vpc_config.public_inbound_acl_rules
  public_outbound_acl_rules                                         = local.vpc_config.public_outbound_acl_rules
  public_route_table_tags                                           = local.vpc_config.public_route_table_tags
  public_subnet_assign_ipv6_address_on_creation                     = local.vpc_config.public_subnet_assign_ipv6_address_on_creation
  public_subnet_enable_dns64                                        = local.vpc_config.public_subnet_enable_dns64
  public_subnet_enable_resource_name_dns_a_record_on_launch         = local.vpc_config.public_subnet_enable_resource_name_dns_a_record_on_launch
  public_subnet_enable_resource_name_dns_aaaa_record_on_launch      = local.vpc_config.public_subnet_enable_resource_name_dns_aaaa_record_on_launch
  public_subnet_ipv6_native                                         = local.vpc_config.public_subnet_ipv6_native
  public_subnet_ipv6_prefixes                                       = local.vpc_config.public_subnet_ipv6_prefixes
  public_subnet_names                                               = local.vpc_config.public_subnet_names
  public_subnet_private_dns_hostname_type_on_launch                 = local.vpc_config.public_subnet_private_dns_hostname_type_on_launch
  public_subnet_suffix                                              = local.vpc_config.public_subnet_suffix
  public_subnet_tags                                                = local.vpc_config.public_subnet_tags
  public_subnet_tags_per_az                                         = local.vpc_config.public_subnet_tags_per_az
  public_subnets                                                    = local.vpc_config.public_subnets
  putin_khuylo                                                      = local.vpc_config.putin_khuylo
  redshift_acl_tags                                                 = local.vpc_config.redshift_acl_tags
  redshift_dedicated_network_acl                                    = local.vpc_config.redshift_dedicated_network_acl
  redshift_inbound_acl_rules                                        = local.vpc_config.redshift_inbound_acl_rules
  redshift_outbound_acl_rules                                       = local.vpc_config.redshift_outbound_acl_rules
  redshift_route_table_tags                                         = local.vpc_config.redshift_route_table_tags
  redshift_subnet_assign_ipv6_address_on_creation                   = local.vpc_config.redshift_subnet_assign_ipv6_address_on_creation
  redshift_subnet_enable_dns64                                      = local.vpc_config.redshift_subnet_enable_dns64
  redshift_subnet_enable_resource_name_dns_a_record_on_launch       = local.vpc_config.redshift_subnet_enable_resource_name_dns_a_record_on_launch
  redshift_subnet_enable_resource_name_dns_aaaa_record_on_launch    = local.vpc_config.redshift_subnet_enable_resource_name_dns_aaaa_record_on_launch
  redshift_subnet_group_name                                        = local.vpc_config.redshift_subnet_group_name
  redshift_subnet_group_tags                                        = local.vpc_config.redshift_subnet_group_tags
  redshift_subnet_ipv6_native                                       = local.vpc_config.redshift_subnet_ipv6_native
  redshift_subnet_ipv6_prefixes                                     = local.vpc_config.redshift_subnet_ipv6_prefixes
  redshift_subnet_names                                             = local.vpc_config.redshift_subnet_names
  redshift_subnet_private_dns_hostname_type_on_launch               = local.vpc_config.redshift_subnet_private_dns_hostname_type_on_launch
  redshift_subnet_suffix                                            = local.vpc_config.redshift_subnet_suffix
  redshift_subnet_tags                                              = local.vpc_config.redshift_subnet_tags
  redshift_subnets                                                  = local.vpc_config.redshift_subnets
  reuse_nat_ips                                                     = local.vpc_config.reuse_nat_ips
  secondary_cidr_blocks                                             = local.vpc_config.secondary_cidr_blocks
  single_nat_gateway                                                = local.vpc_config.single_nat_gateway
  tags                                                              = local.vpc_config.tags
  use_ipam_pool                                                     = local.vpc_config.use_ipam_pool
  vpc_flow_log_iam_policy_name                                      = local.vpc_config.vpc_flow_log_iam_policy_name
  vpc_flow_log_iam_policy_use_name_prefix                           = local.vpc_config.vpc_flow_log_iam_policy_use_name_prefix
  vpc_flow_log_iam_role_name                                        = local.vpc_config.vpc_flow_log_iam_role_name
  vpc_flow_log_iam_role_use_name_prefix                             = local.vpc_config.vpc_flow_log_iam_role_use_name_prefix
  vpc_flow_log_permissions_boundary                                 = local.vpc_config.vpc_flow_log_permissions_boundary
  vpc_flow_log_tags                                                 = local.vpc_config.vpc_flow_log_tags
  vpc_tags                                                          = local.vpc_config.vpc_tags
  vpn_gateway_az                                                    = local.vpc_config.vpn_gateway_az
  vpn_gateway_id                                                    = local.vpc_config.vpn_gateway_id
  vpn_gateway_tags                                                  = local.vpc_config.vpn_gateway_tags
}

module "vpc_endpoints" {
  #checkov:skip=CKV_TF_1: using ref to a specific version
  count  = var.optional_vpc_vars.create_default_vpc_endpoints ? 1 : 0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git//modules/vpc-endpoints?ref=v5.9.0"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc.default_security_group_id]

  endpoints = merge(
    {
      s3 = {
        service          = "s3"
        service_endpoint = "com.amazonaws.${data.aws_region.current.name}.s3"
        service_type     = "Gateway"
        tags             = { Name = "s3-vpc-endpoint" }
        route_table_ids  = flatten([module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      },
      dynamodb = {
        service            = "dynamodb"
        service_endpoint   = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
        service_type       = "Gateway"
        route_table_ids    = flatten([module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
        security_group_ids = [aws_security_group.vpc_tls.id]
        tags               = { Name = "dynamodb-vpc-endpoint" }
      },
      ssm = {
        service             = "ssm"
        service_endpoint    = "com.amazonaws.${data.aws_region.current.name}.ssm"
        private_dns_enabled = true
        subnet_ids          = module.vpc.private_subnets
        security_group_ids  = [aws_security_group.vpc_tls.id]
      },
      ssmmessages = {
        service_endpoint    = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
        service             = "ssmmessages"
        private_dns_enabled = true
        subnet_ids          = module.vpc.private_subnets
        security_group_ids  = [aws_security_group.vpc_tls.id]
      },
      lambda = {
        service_endpoint    = "com.amazonaws.${data.aws_region.current.name}.lambda"
        service             = "lambda"
        private_dns_enabled = true
        subnet_ids          = module.vpc.private_subnets
        security_group_ids  = [aws_security_group.vpc_tls.id]
      },
      sts = {
        service             = "sts"
        service_endpoint    = "com.amazonaws.${data.aws_region.current.name}.sts"
        private_dns_enabled = true
        subnet_ids          = module.vpc.private_subnets
        security_group_ids  = [aws_security_group.vpc_tls.id]
      },
      logs = {
        service_endpoint    = "com.amazonaws.${data.aws_region.current.name}.logs"
        service             = "logs"
        private_dns_enabled = true
        subnet_ids          = module.vpc.private_subnets
        security_group_ids  = [aws_security_group.vpc_tls.id]
      },
      ec2 = {
        service             = "ec2"
        service_endpoint    = "com.amazonaws.${data.aws_region.current.name}.ec2"
        private_dns_enabled = true
        subnet_ids          = module.vpc.private_subnets
        security_group_ids  = [aws_security_group.vpc_tls.id]
      },
      ec2messages = {
        service             = "ec2messages"
        service_endpoint    = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
        private_dns_enabled = true
        subnet_ids          = module.vpc.private_subnets
        security_group_ids  = [aws_security_group.vpc_tls.id]
      },
      kms = {
        service             = "kms"
        service_endpoint    = "com.amazonaws.${data.aws_region.current.name}.kms"
        private_dns_enabled = true
        subnet_ids          = module.vpc.private_subnets
        security_group_ids  = [aws_security_group.vpc_tls.id]
      },
      autoscaling = {
        service             = "autoscaling"
        service_endpoint    = "com.amazonaws.${data.aws_region.current.name}.autoscaling"
        private_dns_enabled = true
        subnet_ids          = module.vpc.private_subnets
        security_group_ids  = [aws_security_group.vpc_tls.id]
      },
      elasticloadbalancing = {
        service             = "elasticloadbalancing"
        service_endpoint    = "com.amazonaws.${data.aws_region.current.name}.elasticloadbalancing"
        private_dns_enabled = true
        subnet_ids          = module.vpc.private_subnets
        security_group_ids  = [aws_security_group.vpc_tls.id]
      },
      efs = {
        service             = "elasticfilesystem"
        service_endpoint    = "com.amazonaws.${data.aws_region.current.name}.elasticfilesystem"
        private_dns_enabled = true
        subnet_ids          = module.vpc.private_subnets
        security_group_ids  = [aws_security_group.vpc_tls.id]
        route_table_ids     = flatten([module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      },
      secretsmanager = {
        service             = "secretsmanager"
        service_endpoint    = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
        private_dns_enabled = true
        subnet_ids          = module.vpc.private_subnets
        security_group_ids  = [aws_security_group.vpc_tls.id]
      }
    }
  )

  tags = merge(local.vpc_config.tags, {
    Endpoint = "true"
  })
}

resource "aws_security_group" "vpc_tls" {
  #checkov:skip=CKV2_AWS_5: Secuirity group is being referenced by the VPC endpoint

  name        = "${data.context_label.this.rendered}-vpc_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = (concat([module.vpc.vpc_cidr_block], module.vpc.vpc_secondary_cidr_blocks))
  }

  egress {
    description = "HTTPS to Managed Services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.vpc_config.tags
}

output "context_tags" {
  value = data.context_tags.this
}
output "vpc_config" {
  value = local.base_vpc_config
}
