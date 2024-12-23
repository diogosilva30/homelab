
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
// Grafana
//////////////////////////////////////////////////////////////////////////////////////
// Create role "Grafana Admin"
resource "zitadel_project_role" "grafana_admin" {
  org_id       = var.org_id
  project_id   = var.project_id
  role_key     = "grafana-admin"
  display_name = "Grafana Admin"
  group        = "role_grafana_admin"
}

// Create role "Grafana Viewer"
resource "zitadel_project_role" "grafana_viewer" {
  org_id       = var.org_id
  project_id   = var.project_id
  role_key     = "grafana-viewer"
  display_name = "Grafana Viewer"
  group        = "role_grafana_viewer"
}

// Grant role "Grafana Admin" to our user
resource "zitadel_user_grant" "default" {
  project_id = var.project_id
  org_id     = var.org_id
  role_keys  = [zitadel_project_role.grafana_admin.role_key]
  user_id    = var.me_user_id
}

// Create application for Grafana
resource "zitadel_application_oidc" "default" {
  project_id                  = var.project_id
  org_id                      = var.org_id
  name                        = "grafana"
  redirect_uris               = ["http://grafana.lab.local/login/generic_oauth"]
  response_types              = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  post_logout_redirect_uris   = ["http://grafana.lab.local/logout"]
  app_type                    = "OIDC_APP_TYPE_WEB"
  auth_method_type            = "OIDC_AUTH_METHOD_TYPE_BASIC"
  version                     = "OIDC_VERSION_1_0"
  clock_skew                  = "0s"
  dev_mode                    = true // Required for HTTP
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
  access_token_role_assertion = false
  id_token_role_assertion     = false
  id_token_userinfo_assertion = false
  additional_origins          = []
}
