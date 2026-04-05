module "zitadel" {
  source = "./zitadel"
}
module "cloudflare" {
  source               = "./cloudflare"
  cloudflare_api_token = var.cloudflare_api_token
  emails_for_access_editorial = [
    "diogosilv30@gmail.com",
    "annehoekman1@gmail.com",
    "bruno.miguel19995@gmail.com",
    "jpmrs1313@gmail.com",
    "ricardoandradeguimaraes@gmail.com"
  ]
}
