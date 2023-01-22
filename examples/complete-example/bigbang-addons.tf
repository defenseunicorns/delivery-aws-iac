
###########################################################
############### Keycloak RDS Database #####################
###########################################################

module "rds_postgres_keycloak" {
  source = "../../modules/rds"

  count = var.keycloak_enabled ? 1 : 0

  # provider alias is needed for every parent module supporting RDS backup replication is a separate region
  providers = {
    aws.region2 = aws.region2
  }

  vpc_id                     = module.vpc.vpc_id
  vpc_cidr                   = module.vpc.vpc_cidr_block
  database_subnet_group_name = module.vpc.database_subnet_group_name
  engine                     = "postgres"
  engine_version             = var.kc_db_engine_version
  family                     = var.kc_db_family
  major_engine_version       = var.kc_db_major_engine_version
  instance_class             = var.kc_db_instance_class
  identifier                 = "${var.cluster_name}-keycloak"
  db_name                    = "keycloak" # Can only be alphanumeric, no hyphens or underscores
  username                   = "kcadmin"
  create_random_password     = false
  password                   = var.keycloak_db_password
  allocated_storage          = var.kc_db_allocated_storage
  max_allocated_storage      = var.kc_db_max_allocated_storage
  create_db_subnet_group     = true
  deletion_protection        = false
  tags                       = local.tags
}
