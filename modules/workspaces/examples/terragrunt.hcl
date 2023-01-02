# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::https://repo1.dso.mil/platform-one/private/cnap/terraform-modules.git//aws/workspaces"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  aws_profile  = "my_profile"
  aws_region   = "us-gov-west-1"
  directory_id = "d-12345abc6d"
  ws_config = {
    user1 = {
      bundle_id                                 = "wsb-clj85qzj1"
      user_name                                 = "user1"
      compute_type_name                         = "STANDARD"
      user_volume_size_gib                      = 100
      root_volume_size_gib                      = 50
      running_mode                              = "ALWAYS_ON"
      running_mode_auto_stop_timeout_in_minutes = 60
    }
    user2 = {
      bundle_id                                 = "wsb-2bs6k5lgn"
      user_name                                 = "user2"
      compute_type_name                         = "POWER"
      user_volume_size_gib                      = 100
      root_volume_size_gib                      = 50
      running_mode                              = "AUTO_STOP"
      running_mode_auto_stop_timeout_in_minutes = 60
    }
  }
}
