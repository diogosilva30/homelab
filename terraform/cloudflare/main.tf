

// Cloudflare related code

data "cloudflare_zone" "zone" {
  name = var.domain
}
locals {
  cloudflare_zone_id = data.cloudflare_zone.zone.id
}

//////////////////////////////////////////////////////////////////////////////////////
// Protect Headscale /web admin page with cloudflare access
//////////////////////////////////////////////////////////////////////////////////////

resource "cloudflare_record" "record_vpn" {
  zone_id = local.cloudflare_zone_id
  name    = "vpn"
  content = var.gateway_address
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = "Record to proxy to fly.io gateway machine"
}


# Allowing access to our list of emails only
resource "cloudflare_zero_trust_access_policy" "vpn_admin_email_policy" {
  account_id = var.cloudflare_account_id
  name       = "VPN admin page email policy"
  decision   = "allow"

  include {
    email = var.emails_for_access_vpn
  }

  require {
    email = var.emails_for_access_vpn
  }
}

resource "cloudflare_zero_trust_access_application" "headscale_protect" {
  zone_id          = local.cloudflare_zone_id
  name             = "Headscale admin page protection"
  domain           = format("%s.%s/%s", "vpn", var.domain, "web") // Final URL is "vpn.<zone>/web"
  session_duration = "24h"
  policies = [
    cloudflare_zero_trust_access_policy.vpn_admin_email_policy.id,
  ]
}

