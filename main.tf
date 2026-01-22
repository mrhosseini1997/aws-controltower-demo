#################################################
# Azure AD SSO Application with SCIM Provisioning
#################################################
# This module creates the Azure AD application, users, and groups.
# Users and groups are synced to AWS IAM Identity Center via SCIM.

module "azuread_sso_app" {
  source = "./modules/azure-ad"

  prefix            = var.aws_app_prefix
  saml_entity_id    = var.aws_saml_entity_id
  saml_acs          = var.aws_saml_acs
  login_url         = var.aws_sso_loging_url
  azure_app_roles   = local.azure_app_roles
  logo_image_base64 = filebase64("${path.module}/assets/logo.png")

  # User and group configuration (transformed in locals.tf)
  users                  = local.users_with_email
  groups                 = local.groups_metadata
  user_group_memberships = local.user_group_memberships
}

#################################################
# AWS IAM Identity Center Configuration
#################################################
# With SCIM enabled, users and groups are provisioned from Azure AD.
# This module only manages permission sets and account assignments.
#
# IMPORTANT: Run SCIM sync first to create groups in AWS before applying.

module "aws_identity_with_sso" {
  source = "./modules/aws-iam"

  identity_store_id = data.aws_ssoadmin_instances.management_account.identity_store_ids[0]
  sso_instance_arn  = data.aws_ssoadmin_instances.management_account.arns[0]

  # Groups are looked up via data sources (SCIM-synced from Azure AD)
  groups                       = local.groups_metadata
  permission_sets              = var.permission_sets
  group_permission_assignments = var.group_permission_assignments

  # Ensure Azure AD resources are created first
  depends_on = [module.azuread_sso_app]
}
