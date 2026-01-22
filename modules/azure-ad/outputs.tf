output "client_id" {
  description = "Azure AD application client ID"
  value       = azuread_application.sso.client_id
}

output "app_role_ids" {
  description = "Azure AD application role IDs"
  value       = local.role_mapping
}

output "user_credentials" {
  description = "Login credentials for Member users"
  sensitive   = true
  value = {
    for user_key in keys(azuread_user.user) : user_key => {
      username = azuread_user.user[user_key].user_principal_name
      password = random_password.user_passwords[user_key].result
    }
  }
}

output "azure_ad_groups" {
  description = "Azure AD security groups (synced to AWS via SCIM)"
  value = {
    for k, g in azuread_group.groups :
    k => {
      id           = g.id
      display_name = g.display_name
      object_id    = g.object_id
    }
  }
}

output "service_principal_id" {
  description = "Azure AD service principal object ID (needed for SCIM provisioning setup)"
  value       = azuread_service_principal.sso_sp.object_id
}
