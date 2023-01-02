## datasources
data "template_file" "additional_drive" {
  template = file("${path.module}/include/additional_drive.tmpl")
}

data "template_file" "wsus" {
  template = file("${path.module}/include/wsus.tmpl")

  vars = {
    #catagories
    critical_update    = var.critical_update
    definition_updates = var.definition_updates
    feature_packs      = var.feature_packs
    security_updates   = var.security_updates
    service_packs      = var.service_packs
    update_rollups     = var.update_rollups
    updates            = var.updates
    drivers            = var.drivers
    driver_sets        = var.driver_sets
    tools              = var.tools
    upgrades           = var.upgrades

    # targeting mode
    targeting_mode = var.targeting_mode

    #global settings
    language = var.language
    timezone = var.timezone

    #products
    enabled_products  = var.enabled_products
    disabled_products = var.disabled_products
  }
}

data "aws_secretsmanager_secret_version" "ad" {
  count     = var.ad_password_secret_name != "" ? 1 : 0
  secret_id = var.ad_password_secret_name
}

# SecretsManager Secret ADAdminSecrets
resource "random_password" "admin_local_pass" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

data "template_file" "wsus_domain_connect_userdata" {
  template = file("${path.module}/include/wsus_domain_join.tmpl")

  vars = {
    region                  = var.region
    ad_domain_user          = var.ad_domain_user
    ad_domain_user_password = var.ad_password_secret_name != "" ? jsondecode(data.aws_secretsmanager_secret_version.ad[0].secret_string)["password"] : var.ad_domain_user_password
    dns_servers             = "${element(var.dns_servers, 0)},${element(var.dns_servers, 1)}"
    local_password          = random_password.admin_local_pass.result
    ad_domain_name          = var.ad_domain_name
  }
}
