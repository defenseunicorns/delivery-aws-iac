# This code is meant as an example of how one may be able to add secrets to their EKS cluster after it is created.

resource "kubernetes_namespace" "iac" {
  metadata {
    name = "iac"
  }
}

resource "kubernetes_secret_v1" "rds_postgres_keycloak_creds" {
  count = var.keycloak_enabled ? 1 : 0
  metadata {
    name      = "keycloak-connect-info"
    namespace = kubernetes_namespace.iac.id
  }
  data = {
    host     = module.rds_postgres_keycloak[0].db_instance_address
    database = module.rds_postgres_keycloak[0].db_instance_name
    username = module.rds_postgres_keycloak[0].db_instance_username
    password = var.keycloak_db_password
  }
}
