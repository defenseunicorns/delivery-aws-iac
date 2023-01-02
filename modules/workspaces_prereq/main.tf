#############################################
###             Prerequisites             ###
#############################################
data "aws_secretsmanager_secret_version" "ad" {
  secret_id = var.ad_secret_name
}

resource "aws_directory_service_directory" "main" {
  name     = var.ad_connector_name
  password = jsondecode(data.aws_secretsmanager_secret_version.ad.secret_string)["password"]
  size     = var.ad_connector_size
  type     = "ADConnector"

  connect_settings {
    customer_username = jsondecode(data.aws_secretsmanager_secret_version.ad.secret_string)["username"]
    customer_dns_ips  = var.ad_connector_customer_dns_ips
    subnet_ids        = var.ad_connector_subnet_ids
    vpc_id            = var.ad_connector_vpc_id
  }
}

resource "aws_iam_role" "workspace_default" {
  name = "workspaces_DefaultRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "workspaces.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy_attachment" "service-access" {
  role       = aws_iam_role.workspace_default.name
  policy_arn = "arn:aws-us-gov:iam::aws:policy/AmazonWorkSpacesServiceAccess"
}

resource "aws_iam_role_policy_attachment" "self-service-access" {
  role       = aws_iam_role.workspace_default.name
  policy_arn = "arn:aws-us-gov:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess"
}

resource "null_resource" "cert-setup" {
  count = var.setup_dod_ca ? 1 : 0
  provisioner "local-exec" {
    command = "for i in ${path.root}/_DoD_Certs/Intermediate_and_Issuing_CA_Certs/*; do aws ds register-certificate --directory-id ${aws_directory_service_directory.main.id} --certificate-data file://$i --type ClientCertAuth --region ${var.aws_region} --profile ${var.aws_profile}; done && aws ds enable-client-authentication --directory-id ${aws_directory_service_directory.main.id} --type SmartCard --region ${var.aws_region} --profile ${var.aws_profile}"
  }
}

#############################################
###          Workspace Directory          ###
#############################################
resource "aws_workspaces_directory" "main" {
  depends_on   = [aws_iam_role_policy_attachment.service-access, aws_iam_role_policy_attachment.self-service-access]
  directory_id = aws_directory_service_directory.main.id
  subnet_ids   = var.subnet_ids

  self_service_permissions {
    change_compute_type  = var.change_compute_type
    increase_volume_size = var.increase_volume_size
    rebuild_workspace    = var.rebuild_workspace
    restart_workspace    = var.restart_workspace
    switch_running_mode  = var.switch_running_mode
  }

  workspace_creation_properties {
    custom_security_group_id            = var.custom_security_group_id
    default_ou                          = var.default_ou
    enable_internet_access              = var.enable_internet_access
    enable_maintenance_mode             = true
    user_enabled_as_local_administrator = true
  }
}