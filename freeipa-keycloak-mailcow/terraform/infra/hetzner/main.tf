resource "hcloud_network" "private_network" {
  name      = var.network_name
  ip_range = var.network_cidr
}

resource "hcloud_network_subnet" "private_subnet" {
  network_id = hcloud_network.private_network.id
  type    = "cloud"
  ip_range = var.subnet_cidr
  network_zone = var.network_zone
}
