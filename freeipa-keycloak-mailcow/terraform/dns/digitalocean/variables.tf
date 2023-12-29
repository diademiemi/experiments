variable "digitalocean_api_token" {
    description = "DigitalOcean API token"
    type = string
}

variable "digitalocean_default_domain" {
    description = "Default DigitalOcean domain"
    type = string
    default = ""
}

variable "digitalocean_default_domain_id" {
    description = "Default DigitalOcean domain"
    type = string
    default = ""
}

variable "digitalocean_default_ttl" {
    description = "Default digitalocean TTL"
    type = number
    default = 120
}

variable "digitalocean_default_type" {
    description = "Default digitalocean type"
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
    }))
}