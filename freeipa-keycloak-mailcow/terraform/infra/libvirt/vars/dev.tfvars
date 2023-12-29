domain       = "terraform.test"
network      = "192.168.21.0/24"
network_name = "terraform"
network_mode = "nat"

vms = [
  {
    hostname = "vyos"

    vcpu   = 2
    memory = 4096

    cloudinit_image = "/tmp/vyos-1.5.0-cloud-init-5G-qemu.qcow2"

    disk_size = 42949672960 # 40 GiB

    password_auth         = true
    root_password         = "root"
    disable_root          = false
    allow_root_ssh_pwauth = true
    ssh_keys              = []

    domain = "terraform.test"
  
    network_interfaces = [
      {
        name         = "eth0"
        network_name = "terraform"

        dhcp = false
      }
    ]

    spice_server_enabled = false

    cloudinit_custom_user_data = <<-EOT

vyos_config_commands:
  - set system host-name 'vyos'
  - set interfaces ethernet eth0 address '192.168.21.2/24'
  - set interfaces ethernet eth0 description 'Libvirt network'
  - set protocols static route 0.0.0.0/0 next-hop '192.168.21.1'
  - set system name-server '9.9.9.9'
  - set service dns forwarding listen-address '192.168.21.2'
  - set service dns forwarding system
  - set service ssh port '22'
  - set service ssh listen-address '192.168.21.2'
  - set system static-host-mapping host-name 'vyos.terraform.test' inet '192.168.21.2'
  - set system static-host-mapping host-name 'mailcow.terraform.test' inet '192.168.21.51'
  - set system static-host-mapping host-name 'freeipa.terraform.test' inet '192.168.21.52'
  - set system static-host-mapping host-name 'keycloak.terraform.test' inet '192.168.21.53'

EOT

    ansible_groups   = ["networking"]
    ansible_user     = "vyos"
    ansible_ssh_pass = "vyos"
    ansible_host     = "192.168.21.2"
  },
  {
    hostname = "mailcow"

    vcpu   = 4
    memory = 8192

    cloudinit_image = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"

    disk_size = 107374182400 # 100 GiB

    password_auth         = true
    root_password         = "root"
    disable_root          = false
    allow_root_ssh_pwauth = true
    ssh_keys              = []

    domain = "terraform.test"

    network_interfaces = [
      {
        name         = "ens3"
        network_name = "terraform"

        dhcp = false

        ip      = "192.168.21.51/24"
        gateway = "192.168.21.1"

        nameservers = [
          "192.168.21.2"
        ]
      }
    ]

    spice_server_enabled = false

    ansible_groups   = ["linux", "ubuntu", "mailcowserver"]
    ansible_user     = "root"
    ansible_ssh_pass = "root"
  },
  {
    hostname = "ipa"

    vcpu   = 4
    memory = 8192

    cloudinit_image = "https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2"

    disk_size = 107374182400 # 100 GiB

    password_auth         = true
    root_password         = "root"
    disable_root          = false
    allow_root_ssh_pwauth = true
    ssh_keys              = []

    domain = "terraform.test"

    network_interfaces = [
      {
        name         = "ens3"
        network_name = "terraform"

        dhcp = false

        ip      = "192.168.21.52/24"
        gateway = "192.168.21.1"

        nameservers = [
          "192.168.21.2"
        ]
      }
    ]

    spice_server_enabled = false

    # CentOS uses a custom cloud-init network data version 1 still
    cloudinit_use_network_data = false
    cloudinit_custom_network_data = <<-EOT

version: 1
config:
  - type: physical
    name: eth0
    subnets:
      - type: static
        address: 192.168.21.52/24
        gateway: 192.168.21.1
  - type: nameserver
    search:
      - terraform.test
    address:
      - 192.168.21.2
EOT

    ansible_groups   = ["linux", "centos", "ipaserver"]
    ansible_user     = "root"
    ansible_ssh_pass = "root"
  },
  {
    hostname = "keycloak"

    vcpu   = 4
    memory = 8192

    cloudinit_image = "https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2"

    disk_size = 107374182400 # 100 GiB

    password_auth         = true
    root_password         = "root"
    disable_root          = false
    allow_root_ssh_pwauth = true
    ssh_keys              = []

    domain = "terraform.test"

    network_interfaces = [
      {
        name         = "ens3"
        network_name = "terraform"

        dhcp = false

        ip      = "192.168.21.53/24"
        gateway = "192.168.21.1"

        nameservers = [
          "192.168.21.2"
        ]
      }
    ]

    spice_server_enabled = false

    # CentOS uses a custom cloud-init network data version 1 still
    cloudinit_use_network_data = false
    cloudinit_custom_network_data = <<-EOT

version: 1
config:
  - type: physical
    name: eth0
    subnets:
      - type: static
        address: 192.168.21.53/24
        gateway: 192.168.21.1
  - type: nameserver
    search:
      - terraform.test
    address:
      - 192.168.21.2
EOT

    ansible_groups   = ["linux", "centos", "keycloakserver"]
    ansible_user     = "root"
    ansible_ssh_pass = "root"
  },
]


