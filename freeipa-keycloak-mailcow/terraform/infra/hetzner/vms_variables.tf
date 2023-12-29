variable "hcloud_api_token" {
  description = "API token for Hetzner Cloud"
  type        = string
  sensitive = true
}

variable "default_domain" {
  description = "Default domain"
  type        = string
  default     = ""
}

variable "vms" {
  description = "List of VMs to create"
  type = list(object({
    hostname = string
    domain   = optional(string)
    server_type = string
    image       = string
    datacenter    = string
    ipv6_enabled = optional(bool)

    network_id         = optional(string)
    network_ip         = optional(string)
    network_ip_aliases = optional(list(string))

    ansible_name   = optional(string)
    ansible_host   = optional(string)
    ansible_user   = optional(string)
    ansible_ssh_pass = optional(string)
    ansible_groups = optional(list(string))
  }))
  default = []
}
