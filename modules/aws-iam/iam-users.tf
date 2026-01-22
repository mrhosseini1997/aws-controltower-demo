#################################################
# AWS IAM Identity Center Users (SCIM Provisioned)
#################################################
# With SCIM enabled, users are automatically provisioned from Azure AD.
# This file is kept for reference but user creation is handled by SCIM sync.
#
# If you need to look up SCIM-provisioned users, use data sources:
#
# data "aws_identitystore_user" "user" {
#   identity_store_id = var.identity_store_id
#   alternate_identifier {
#     unique_attribute {
#       attribute_path  = "UserName"
#       attribute_value = "user@example.com"
#     }
#   }
# }
#
# Note: Users must be synced via SCIM before they can be referenced.
