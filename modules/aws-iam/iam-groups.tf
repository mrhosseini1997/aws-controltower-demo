#################################################
# AWS IAM Identity Center Groups (SCIM Provisioned)
#################################################
# With SCIM enabled, groups are automatically provisioned from Azure AD.
# We use data sources to look up SCIM-synced groups for permission assignments.
#
# Note: Groups must be synced via SCIM before they can be referenced.
# The initial terraform apply may fail if groups haven't synced yet.
# Run SCIM sync first, then apply terraform.

data "aws_identitystore_group" "scim_groups" {
  for_each = var.groups

  identity_store_id = var.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = title(each.key)
    }
  }
}

# Group memberships are handled by SCIM sync from Azure AD.
# No need to manage aws_identitystore_group_membership resources.
