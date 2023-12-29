subnet_cidr      = "10.0.1.0/24"
network_cidr = "10.0.0.0/16"
network_name = "dev"

# domain is not actually used for the dns records, only the subdomains are
# I change this with Ansible, I just don't want to define it in the tfvars
default_domain = "dev.terraform.test"

vms = [
  {
    hostname = "mailcow"
    # domain  = "dev.terraform.test"
    server_type = "cx31"
    image       = "rocky-9"
    datacenter    = "nbg1-dc3"
    ipv6_enabled = true

    network_ip         = "10.0.1.51"
  },
    {
    hostname = "ipa"
    # domain  = "dev.terraform.test"
    server_type = "cax21"
    image       = "rocky-9"
    datacenter    = "nbg1-dc3"
    ipv6_enabled = true

    network_ip         = "10.0.1.52"
    ansible_groups   = ["ipaserver"]
  },
    {
    hostname = "keycloak"
    # domain  = "dev.terraform.test"
    server_type = "cax21"
    image       = "rocky-9"
    datacenter    = "nbg1-dc3"
    ipv6_enabled = true

    network_ip         = "10.0.1.53"
  },
  // Add more VM configurations as needed
]
