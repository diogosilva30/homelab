// The default ORG
data "zitadel_org" "default" {
  # LAB ORG
  id = "299422866410111172"
}
data "zitadel_human_user" "me" {
  org_id = data.zitadel_org.default.id
  # dsilva user
  user_id = "299422866410766532"
}

// Create project for holding kubernetes applications
resource "zitadel_project" "lab_project" {
  name                     = "Kubernetes Lab Applications"
  org_id                   = data.zitadel_org.default.id
  project_role_assertion   = true
  project_role_check       = true
  has_project_check        = true
  private_labeling_setting = "PRIVATE_LABELING_SETTING_ENFORCE_PROJECT_RESOURCE_OWNER_POLICY"
}

// Add user to project
resource "zitadel_project_member" "this" {
  org_id     = data.zitadel_org.default.id
  project_id = zitadel_project.lab_project.id
  user_id    = data.zitadel_human_user.me.id
  roles      = ["PROJECT_OWNER"]
}

// Setup grafana application
module "grafana" {
  source     = "./zitadel_grafana"
  project_id = zitadel_project.lab_project.id
  org_id     = data.zitadel_org.default.id
  me_user_id = data.zitadel_human_user.me.id
}

// Setup bytestash application
module "bytestash" {
  source     = "./zitadel_bytestash"
  project_id = zitadel_project.lab_project.id
  org_id     = data.zitadel_org.default.id
  me_user_id = data.zitadel_human_user.me.id
}

