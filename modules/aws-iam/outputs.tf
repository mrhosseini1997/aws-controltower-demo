# With SCIM enabled, users are provisioned from Azure AD.
# User IDs can be looked up via data sources if needed.

output "sso_groups" {
  description = "SCIM-synced group IDs from AWS IAM Identity Center"
  value = {
    for k, g in data.aws_identitystore_group.scim_groups :
    k => g.group_id
  }
}

output "aws_access_portal_url" {
  description = "AWS IAM Identity Center access portal URL"
  value       = local.aws_access_portal_url
}
