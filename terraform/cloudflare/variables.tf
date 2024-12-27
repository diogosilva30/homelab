variable "cloudflare_api_token" {
  type        = string
  sensitive   = true
  description = "API token to manage cloudflare"
}
variable "cloudflare_account_id" {
  type        = string
  description = "Account ID of cloudflare"
  default     = "8f2f7b46178f7faf8e69b9f3ef8282bd"
}
variable "domain" {
  default = "dsilva.dev"
  type    = string
}
variable "emails_for_access_vpn" {
  type        = list(string)
  description = "List of emails that can access VPN admin page."
}
variable "gateway_address" {
  type    = string
  default = "gw-dsilva.fly.dev"
}
