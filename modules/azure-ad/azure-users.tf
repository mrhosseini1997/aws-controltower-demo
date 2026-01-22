#################################################
# Azure AD User Provisioning
#################################################
# Users are created in Azure AD and synced to AWS via SCIM
# Group membership (in azure-groups.tf) determines AWS permissions

resource "random_password" "user_passwords" {
  for_each    = { for k, v in var.users : k => v if v.azure_ad_user_type == "Member" }
  length      = 16
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
}

resource "azuread_user" "user" {
  for_each = { for k, v in var.users : k => v if v.azure_ad_user_type == "Member" }

  user_principal_name = each.value.user_principal_name
  display_name        = each.value.display_name
  mail_nickname       = each.value.mail_nickname
  given_name          = each.value.given_name
  surname             = each.value.surname
  mail                = each.value.email
  password            = random_password.user_passwords[each.key].result
  usage_location      = "US"
}

resource "azuread_invitation" "guest_user" {
  for_each           = { for k, v in var.users : k => v if v.azure_ad_user_type == "Guest" }
  user_display_name  = each.value.display_name
  user_email_address = each.value.email
  redirect_url       = "https://portal.azure.com"

  message {
    body = "You have been invited to access AWS via Single Sign-On."
  }
}

# Update guest user profile with givenName and surname (required for SCIM)
resource "null_resource" "update_guest_user_profile" {
  for_each = { for k, v in var.users : k => v if v.azure_ad_user_type == "Guest" }

  triggers = {
    user_id    = azuread_invitation.guest_user[each.key].user_id
    given_name = each.value.given_name
    surname    = each.value.surname
  }

  provisioner "local-exec" {
    command = <<-EOT
      az rest --method PATCH \
        --url "https://graph.microsoft.com/v1.0/users/${azuread_invitation.guest_user[each.key].user_id}" \
        --headers "Content-Type=application/json" \
        --body '{"givenName": "${each.value.given_name}", "surname": "${each.value.surname}"}'
    EOT
  }

  depends_on = [azuread_invitation.guest_user]
}

#################################################
# Azure AD Group Assignments to Enterprise App
#################################################
# Assign groups to the enterprise app for SCIM provisioning

resource "azuread_app_role_assignment" "group_assignments" {
  for_each = var.groups

  app_role_id         = local.role_mapping[each.key]
  resource_object_id  = azuread_service_principal.sso_sp.object_id
  principal_object_id = azuread_group.groups[each.key].object_id
}
