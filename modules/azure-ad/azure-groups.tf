#################################################
# Azure AD Security Groups for SCIM Provisioning
#################################################
# These groups will be synced to AWS IAM Identity Center via SCIM
# Group membership determines AWS permissions

resource "azuread_group" "groups" {
  for_each = var.groups

  display_name            = title(replace(each.key, "_", " "))
  description             = each.value.description
  security_enabled        = true
  owners                  = [data.azuread_client_config.current.object_id]
  prevent_duplicate_names = true
}

#################################################
# Group Membership Assignments
#################################################

locals {
  # Flatten user_group_memberships into individual membership records
  group_memberships = flatten([
    for user_key, groups in var.user_group_memberships : [
      for group_key in groups : {
        key       = "${user_key}-${group_key}"
        user_key  = user_key
        group_key = group_key
      }
    ]
  ])

  # Separate memberships by user type
  member_group_memberships = {
    for m in local.group_memberships :
    m.key => m if lookup(var.users, m.user_key, null) != null && var.users[m.user_key].azure_ad_user_type == "Member"
  }

  guest_group_memberships = {
    for m in local.group_memberships :
    m.key => m if lookup(var.users, m.user_key, null) != null && var.users[m.user_key].azure_ad_user_type == "Guest"
  }
}

# Add Member users to groups
resource "azuread_group_member" "member_users" {
  for_each = local.member_group_memberships

  group_object_id  = azuread_group.groups[each.value.group_key].object_id
  member_object_id = azuread_user.user[each.value.user_key].object_id
}

# Add Guest users to groups
resource "azuread_group_member" "guest_users" {
  for_each = local.guest_group_memberships

  group_object_id  = azuread_group.groups[each.value.group_key].object_id
  member_object_id = azuread_invitation.guest_user[each.value.user_key].user_id
}
