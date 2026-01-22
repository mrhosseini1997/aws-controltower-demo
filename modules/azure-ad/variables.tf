variable "prefix" {
  type        = string
  description = "Prefix for resources, used to avoid name collisions"
}

variable "saml_entity_id" {
  type        = string
  description = "AWS SAML entity ID for the IAM Identity Center SSO Application"
}

variable "saml_acs" {
  type        = string
  description = "AWS SAML Assertion Consumer Service (ACS) URL"
}

variable "login_url" {
  type        = string
  description = "The Login URL"
  default     = ""
}

variable "azure_app_roles" {
  description = "Map of Azure AD App roles (derived from groups)"
  type        = map(string)
}

variable "logo_image_base64" {
  description = "Base64-encoded logo image for the Azure AD application"
  type        = string
}

variable "users" {
  description = "Map of users with email as key"
  type = map(object({
    user_principal_name = string
    email               = string
    display_name        = string
    given_name          = string
    surname             = string
    mail_nickname       = string
    azure_ad_user_type  = optional(string, "Guest")
  }))
}

variable "groups" {
  description = "Map of group definitions"
  type = map(object({
    description = string
  }))
}

variable "user_group_memberships" {
  description = "Map of user_key to list of group_keys"
  type        = map(list(string))
}
