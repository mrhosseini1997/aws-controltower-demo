locals {
  # Transform users - priority: email > user_principal_name > key
  users_with_email = {
    for user_key, user in var.identity_users :
    user_key => {
      display_name        = user.display_name
      given_name          = user.given_name
      surname             = user.surname
      azure_ad_user_type  = user.azure_ad_user_type
      user_principal_name = coalesce(user.email, user.user_principal_name, user_key)
      email               = coalesce(user.email, user.user_principal_name, user_key)
      mail_nickname       = coalesce(user.mail_nickname, replace(split("@", coalesce(user.email, user.user_principal_name, user_key))[0], ".", "-"))
    }
  }

  # Derive Azure app roles from groups (group_key => Title Case display name)
  azure_app_roles = {
    for group_key, group in var.identity_groups :
    group_key => title(replace(group_key, "_", " "))
  }

  # Convert group-centric memberships to user-centric for compatibility
  # From: group = { members = ["user1", "user2"] }
  # To:   user1 = ["group1", "group2"]
  user_group_memberships = {
    for user_key in keys(var.identity_users) :
    user_key => [
      for group_key, group in var.identity_groups :
      group_key if contains(group.members, user_key)
    ]
  }

  # Groups without members (just the metadata)
  groups_metadata = {
    for group_key, group in var.identity_groups :
    group_key => {
      description = group.description
    }
  }
}
