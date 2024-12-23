// The default ORG
data "zitadel_org" "default" {
  # LAB ORG
  id = "299422866410111172"
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

// Setup grafana application
module "grafana" {
  source     = "./zitadel_grafana"
  project_id = zitadel_project.lab_project.id
  org_id     = data.zitadel_org.default.id
}
