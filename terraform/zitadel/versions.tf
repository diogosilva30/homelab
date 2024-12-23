terraform {
  required_providers {
    zitadel = {
      source  = "zitadel/zitadel"
      version = "1.2.0"
    }
  }
}

provider "zitadel" {
  domain   = "idp.lab.local"
  insecure = "true"
  port     = "80"
  // Create the file by running "./hack/get_zitadel_credentials.sh"
  jwt_profile_file = "zitadel-credentials.json"
}
