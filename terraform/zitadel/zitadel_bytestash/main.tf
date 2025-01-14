
terraform {
  required_providers {
    zitadel = {
      source  = "zitadel/zitadel"
      version = "1.2.0"
    }
  }
}

variable "project_id" {
  type        = string
  description = "The project id"
}
variable "org_id" {
  type        = string
  description = "The org id"
}
variable "me_user_id" {
  type        = string
  description = "The user id"
}
//////////////////////////////////////////////////////////////////////////////////////
// Bytestash
//////////////////////////////////////////////////////////////////////////////////////

// Create application for Bytestash
resource "zitadel_application_oidc" "default" {
  project_id                  = var.project_id
  org_id                      = var.org_id
  name                        = "bytestash"
  redirect_uris               = ["http://bytestash.lab.local/api/auth/oidc/callback"]
  response_types              = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  post_logout_redirect_uris   = []
  app_type                    = "OIDC_APP_TYPE_WEB"
  auth_method_type            = "OIDC_AUTH_METHOD_TYPE_BASIC"
  version                     = "OIDC_VERSION_1_0"
  clock_skew                  = "0s"
  dev_mode                    = true // Required for HTTP
  access_token_type           = "OIDC_TOKEN_TYPE_JWT"
  access_token_role_assertion = true
  id_token_role_assertion     = true
  id_token_userinfo_assertion = true
  additional_origins          = []
}
