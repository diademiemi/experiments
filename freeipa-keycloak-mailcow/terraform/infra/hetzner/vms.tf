module "hetzner_vm" {
  source     = "diademiemi/vm/hetzner"
  version    = "1.0.0"

  depends_on = [
    hcloud_network.private_network,
    hcloud_network_subnet.private_subnet
  ]

  for_each = { for vm in var.vms : vm.hostname => vm }

  hcloud_token = var.hcloud_api_token

  server_name = each.value.hostname
  server_domain = coalesce(each.value.domain, var.default_domain)
  server_type = each.value.server_type
  image       = each.value.image
  datacenter    = each.value.datacenter

  labels = {
    "managed_by" = "terraform"
  }

  ipv6_enabled = each.value.ipv6_enabled

  network_id         = coalesce(each.value.network_id, hcloud_network.private_network.id, 0)
  network_ip         = each.value.network_ip
  network_ip_aliases = try(each.value.network_ip_aliases, [])

  ansible_name   = each.value.ansible_name
  ansible_host   = each.value.ansible_host
  ansible_user   = each.value.ansible_user
  ansible_ssh_pass = each.value.ansible_ssh_pass
  ansible_groups = each.value.ansible_groups
}

# Create list like:
# - name: "vm"
#   value: $vm.value.primary_ipv4_address
#   type: "A"
#   ttl: 5
output "dns_records" {
  depends_on = [module.hetzner_vm]
  value = [for vm_hostname, vm in module.hetzner_vm : {
    name: length(split(".", vm.server_domain)) >= 3 ? "${vm_hostname}.${join(".", slice(split(".", vm.server_domain), 0, length(split(".", vm.server_domain)) - 2))}" : vm_hostname
    value: vm.primary_ipv4_address,  # Replace with the actual attribute for the primary IPv4 address
    type: "A"
  }]
}
