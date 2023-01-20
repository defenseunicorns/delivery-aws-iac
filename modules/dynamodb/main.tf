###Need to research more###
data "aws_caller_identity" "current" {}

################################################################################
# DynamoDB Module
################################################################################

module "dynamodb_table"  {
    source       = "terraform-aws-modules/dynamodb-table/aws"
    name         = var.name
    billing_mode = var.billing_mode
    
     ### Unsure of this ####
    
    attributes = [
        {
            name = "log_id"
            type = "S"
            name = "timestamp"
            type = "N"
        }
        
    ]

    global_secondary_indexes = {
        name = "log_type"
        hash_key = "log_type"
        range_key = "timestamp"
        projection_type = "ALL"
    }
    server_side_encryption_enabled = true
    tags         = var.tags

    

}
