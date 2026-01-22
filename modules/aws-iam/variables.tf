variable "identity_store_id" {
  type        = string
  description = "AWS Identity Store ID"
}

variable "sso_instance_arn" {
  type        = string
  description = "AWS SSO instance ARN"
}

variable "groups" {
  description = "Map of group definitions (used to look up SCIM-synced groups)"
  type = map(object({
    description = string
  }))
}

variable "permission_sets" {
  description = "Map of permission sets with policies"
  type = map(object({
    description          = string
    session_duration     = optional(string, "PT8H")
    managed_policies     = optional(list(string), [])
    inline_policy        = optional(string, "")
    permissions_boundary = optional(string, "")
  }))
}

variable "group_permission_assignments" {
  description = "List of group to permission set assignments per account"
  type = list(object({
    group          = string
    permission_set = string
    account_id     = string
  }))
}
