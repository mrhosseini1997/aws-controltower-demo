#################################################
# Permission Sets
#################################################

resource "aws_ssoadmin_permission_set" "permission_set" {
  for_each = var.permission_sets

  instance_arn     = var.sso_instance_arn
  name             = title(replace(each.key, "_", " "))
  description      = each.value.description
  session_duration = each.value.session_duration

  tags = {
    ManagedBy = "Terraform"
  }
}

#################################################
# Managed Policy Attachments
#################################################

locals {
  # Flatten permission_sets to attach each managed policy
  flattened_policy_attachments = {
    for item in flatten([
      for ps_key, ps in var.permission_sets : [
        for policy_arn in coalesce(ps.managed_policies, []) : {
          key        = "${ps_key}-${basename(policy_arn)}"
          ps_key     = ps_key
          policy_arn = policy_arn
        }
      ]
    ]) : item.key => item
  }

  # Permission sets with inline policies
  permission_sets_with_inline = {
    for ps_key, ps in var.permission_sets :
    ps_key => ps if ps.inline_policy != null && ps.inline_policy != ""
  }

  # Permission sets with permissions boundaries
  permission_sets_with_boundary = {
    for ps_key, ps in var.permission_sets :
    ps_key => ps if ps.permissions_boundary != null && ps.permissions_boundary != ""
  }

  # Convert group_permission_assignments list to map
  assignment_map = {
    for item in var.group_permission_assignments :
    "${item.group}-${item.permission_set}-${item.account_id}" => item
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "policy_attachment" {
  for_each = local.flattened_policy_attachments

  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.permission_set[each.value.ps_key].arn
  managed_policy_arn = each.value.policy_arn
}

#################################################
# Inline Policy Attachments
#################################################

resource "aws_ssoadmin_permission_set_inline_policy" "inline_policy" {
  for_each = local.permission_sets_with_inline

  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.permission_set[each.key].arn
  inline_policy      = each.value.inline_policy
}

#################################################
# Permissions Boundary Attachments
#################################################

resource "aws_ssoadmin_permissions_boundary_attachment" "boundary" {
  for_each = local.permission_sets_with_boundary

  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.permission_set[each.key].arn

  permissions_boundary {
    managed_policy_arn = each.value.permissions_boundary
  }
}

#################################################
# Account Assignments
#################################################
# Assign SCIM-synced groups to permission sets for specific accounts

resource "aws_ssoadmin_account_assignment" "assignment" {
  for_each = local.assignment_map

  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.permission_set[each.value.permission_set].arn
  principal_type     = "GROUP"
  principal_id       = data.aws_identitystore_group.scim_groups[each.value.group].group_id
  target_type        = "AWS_ACCOUNT"
  target_id          = each.value.account_id
}
