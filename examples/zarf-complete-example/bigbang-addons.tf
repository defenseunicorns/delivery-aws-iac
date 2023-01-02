
###########################################################
############### Keycloak RDS Database #####################
###########################################################

module "rds_postgres_keycloak" {
  source = "git::https://github.com/defenseunicorns/iac.git//modules/rds?ref=v0.0.0-alpha.0"

# provider alias is needed for every parent module supporting RDS backup replication is a separate region
  providers = {
    aws.region2 = aws.region2
  }

  count                      = local.keycloak_enabled ? 1 : 0

  vpc_id                     = module.vpc.vpc_id
  vpc_cidr                   = module.vpc.vpc_cidr_block
  database_subnet_group_name = module.vpc.database_subnet_group_name
  engine                     = "postgres"
  engine_version             = local.kc_db_engine_version
  family                     = local.kc_db_family
  major_engine_version       = local.kc_db_major_engine_version
  instance_class             = local.kc_db_instance_class
  identifier                 = "${local.cluster_name}-keycloak"
  db_name                    = "keycloak" # Can only be alphanumeric, no hyphens or underscores
  username                   = "kcadmin"
  create_random_password     = false
  password                   = local.keycloak_db_password
  allocated_storage          = local.kc_db_allocated_storage
  max_allocated_storage      = local.kc_db_max_allocated_storage
  create_db_subnet_group     = true
  deletion_protection        = false
  tags                       = local.tags
}
