locals {
  base_keycloak_kms_key_config = {
    description               = "Keycloak Key"
    deletion_window_in_days   = 7
    enable_key_rotation       = true
    multi_region              = true
    key_owners                = var.keycloak_config_opts.key_owners
    tags                      = data.context_tags.this.tags
    create_external           = false
    key_usage                 = "ENCRYPT_DECRYPT" //"What the key is intended to be used for (ENCRYPT_DECRYPT or SIGN_VERIFY)"
    customer_master_key_spec  = "SYMMETRIC_DEFAULT"
    policy_default_identities = []
    policy_default_services   = []
    key_alias_prefix          = "alias/${data.context_label.this.rendered}"
  }
  base_keycloak_db_config = {
    secret_name                    = "keycloak-db-secret-${data.context_label.this.rendered}"
    secret_recovery_window         = 7
    identifier                     = "keycloak-db"
    instance_class                 = "db.t4g.large"
    db_name                        = "keycloakdb"
    instance_use_identifier_prefix = true
    allocated_storage              = 20
    max_allocated_storage          = 500
    backup_retention_period        = 30
    backup_window                  = "03:00-06:00"
    maintenance_window             = "Mon:00:00-Mon:03:00"
    engine                         = "postgres"
    engine_version                 = "15.6"
    major_engine_version           = "15"
    family                         = "postgres15"
    username                       = "keycloak"
    port                           = "5432"
    manage_master_user_password    = false
    multi_az                       = false
    copy_tags_to_snapshot          = true
    allow_major_version_upgrade    = false
    auto_minor_version_upgrade     = false
    deletion_protection            = true
    snapshot_identifier            = "" //var.keycloak_db_snapshot
  }

  base_uds_keycloak_config = {
    kms_config = local.base_keycloak_kms_key_config
    db_config  = local.base_keycloak_db_config
    tags       = data.context_tags.this.tags
  }
  devx_overrides = {
    db_config  = { deletion_protection = false }
    kms_config = { description = "DevX Keycloak Key" }
  }

}
