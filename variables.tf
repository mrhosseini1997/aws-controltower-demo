variable "aws_app_prefix" {
  type        = string
  description = "Prefix for resources, used to avoid name collisions"
  default     = "control-tower-aws-aad-sso"
}

variable "aws_saml_entity_id" {
  type        = string
  description = "SAML entity ID for the AWS SSO instance"
  sensitive   = true
}

variable "aws_saml_acs" {
  type        = string
  description = "SAML Assertion Consumer Service URL for the AWS SSO instance"
  sensitive   = true
}

variable "aws_sso_loging_url" {
  type        = string
  description = "AWS SSO Login URL"
  sensitive   = true
}

#################################################
# User Configuration
#################################################
# Two formats supported:
# 1. Key is email: { "john@company.com" = { display_name = "John" ... } }
# 2. Key is identifier with email field: { john = { email = "john@company.com" ... } }

variable "identity_users" {
  description = "Map of users"
  type = map(object({
    display_name        = string
    given_name          = string
    surname             = string
    email               = optional(string, "")  # If empty, key is used as email
    user_principal_name = optional(string, "")  # Deprecated, use email or key
    mail_nickname       = optional(string, "")  # Auto-derived if not provided
    azure_ad_user_type  = optional(string, "Guest")
  }))
  default = {}
}

#################################################
# Group Configuration
#################################################
# Groups with their members and description

variable "identity_groups" {
  description = "Map of groups with description and member list"
  type = map(object({
    description = string
    members     = list(string) # List of user keys from identity_users
  }))
  default = {}
}

#################################################
# Permission Sets
#################################################
# Flexible permission sets with managed policies and/or inline policies

variable "permission_sets" {
  description = "Map of permission sets with policies"
  type = map(object({
    description       = string
    session_duration  = optional(string, "PT8H") # ISO 8601 duration, default 8 hours
    managed_policies  = optional(list(string), [])
    inline_policy     = optional(string, "")     # JSON policy document
    permissions_boundary = optional(string, "")  # ARN of permissions boundary
  }))
  default = {}
}

#################################################
# Group Permission Assignments
#################################################
# Assign groups to permission sets for specific accounts

variable "group_permission_assignments" {
  description = "List of group to permission set assignments per account"
  type = list(object({
    group          = string
    permission_set = string
    account_id     = string
  }))
  default = []
}
