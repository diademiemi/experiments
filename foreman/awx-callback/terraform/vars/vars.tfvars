domain       = "terraform.local"
network      = "192.168.21.0/24"
network_name = "foreman"
network_mode = "nat"

vms = [
  {
    hostname = "foreman"

    vcpu   = 8
    memory = 16384

    cloudinit_image = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"

    disk_size = 107374182400 # 100 GiB

    password_auth         = true
    root_password         = "root"
    disable_root          = false
    allow_root_ssh_pwauth = true
    ssh_keys              = []

    domain = "terraform.local"

    network_interfaces = [
      {
        name         = "ens3"
        network_name = "foreman"

        dhcp = false

        ip      = "192.168.21.50/24"
        gateway = "192.168.21.1"

        nameservers = [
          "9.9.9.9",
          "1.1.1.1"
        ]
      }
    ]

    spice_server_enabled = false

    ansible_groups   = ["vm"]
    ansible_user     = "root"
    ansible_ssh_pass = "root"
  },
  {
    hostname = "awx"

    vcpu   = 8
    memory = 16384

    cloudinit_image = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"

    disk_size = 107374182400 # 100 GiB

    password_auth         = true
    root_password         = "root"
    disable_root          = false
    allow_root_ssh_pwauth = true
    ssh_keys              = []

    domain = "terraform.local"

    network_interfaces = [
      {
        name         = "ens3"
        network_name = "foreman"

        dhcp = false

        ip      = "192.168.21.51/24"
        gateway = "192.168.21.1"

        nameservers = [
          "9.9.9.9",
          "1.1.1.1"
        ]
      }
    ]

    spice_server_enabled = false

    ansible_groups   = ["vm"]
    ansible_user     = "root"
    ansible_ssh_pass = "root"
  }
]

client_hostname = "client"

client_vcpu   = 4
client_memory = 8192

client_network_interfaces = [
  {
    network_name = "foreman"
  }
]

client_spice_server_enabled = false
