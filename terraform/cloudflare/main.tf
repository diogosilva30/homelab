

// Cloudflare related code

data "cloudflare_zone" "zone" {
  filter = {
    name = var.domain
  }
}
locals {
  cloudflare_zone_id = data.cloudflare_zone.zone.zone_id
}

//////////////////////////////////////////////////////////////////////////////////////
// Protect The Academic Editorial with cloudflare access
//////////////////////////////////////////////////////////////////////////////////////

resource "cloudflare_zero_trust_access_policy" "editorial_email_policy" {
  account_id = var.cloudflare_account_id
  name       = "The Academic Editorial email policy"
  decision   = "allow"

  include = [for e in var.emails_for_access_editorial : {
    email = {
      email = e
    }
  }]
}

resource "cloudflare_zero_trust_access_policy" "editorial_stripe_webhook_bypass_policy" {
  account_id = var.cloudflare_account_id
  name       = "The Academic Editorial Stripe webhook bypass policy"
  decision   = "bypass"

  include = [{
    everyone = {}
  }]
}

resource "cloudflare_zero_trust_access_application" "editorial_stripe_webhook_bypass" {
  zone_id = local.cloudflare_zone_id
  name    = "The Academic Editorial Stripe webhook bypass"
  domain  = format("%s.%s/api/payments/stripe/webhook", var.editorial_subdomain, var.domain)
  type    = "self_hosted"
  policies = [{
    id = cloudflare_zero_trust_access_policy.editorial_stripe_webhook_bypass_policy.id
  }]
}

resource "cloudflare_zero_trust_access_application" "editorial_protect" {
  zone_id          = local.cloudflare_zone_id
  name             = "The Academic Editorial protection"
  domain           = format("%s.%s", var.editorial_subdomain, var.domain)
  type             = "self_hosted"
  session_duration = "24h"
  policies = [{
    id = cloudflare_zero_trust_access_policy.editorial_email_policy.id
  }]
}

