variable "cloudflare_api_token" {
    description = "Cloudflare API token"
    type = string
}

variable "cloudflare_default_domain_id" {
    description = "Default Cloudflare zone ID"
    type = string
    default = ""
}

variable "cloudflare_default_domain" {
    description = "Default Cloudflare domain"
    type = string
    default = ""
}

variable "cloudflare_default_ttl" {
    description = "Default Cloudflare TTL"
    type = number
    default = 120
}

variable "cloudflare_default_proxied" {
    description = "Default Cloudflare proxied"
    type = bool
    default = false
}

variable "cloudflare_default_allow_overwrite" {
    description = "Default Cloudflare allow_overwrite"
    type = bool
    default = true
}

variable "cloudflare_default_type" {
    description = "Default Cloudflare type"
    type = string
    default = "A"
}

variable "dns_records" {
    description = "List of DNS records to create"
    default     = []
    type = list(object({
        domain_id = optional(string)
        domain = optional(string)
        name = string
        value = string
        type = optional(string)
        ttl = optional(number)
        proxied = optional(bool)
        allow_overwrite = optional(bool)
    }))
}