module "vm" {
  source     = "diademiemi/vm/libvirt"
  version    = "4.7.1"
  depends_on = [
    libvirt_network.network,
    null_resource.build-vyos-qcow2
    ]

  for_each = { for vm in var.vms : vm.hostname => vm }

  hostname = each.value.hostname
  domain   = each.value.domain

  vcpu   = each.value.vcpu
  memory = each.value.memory

  autostart = each.value.autostart

  cloudinit_image = each.value.cloudinit_image

  disk_size         = each.value.disk_size
  libvirt_pool      = each.value.libvirt_pool
  disk_passthroughs = coalesce(each.value.disk_passthroughs, [])
  iso_urls          = coalesce(each.value.iso_urls, [])
  iso_paths         = coalesce(each.value.iso_paths, [])

  ssh_keys              = each.value.ssh_keys
  password_auth         = coalesce(each.value.password_auth, false)
  root_password         = coalesce(each.value.root_password, "")
  allow_root_ssh_pwauth = coalesce(each.value.allow_root_ssh_pwauth, false)
  disable_root          = coalesce(each.value.disable_root, true)

  # libvirt_external_interface = each.value.libvirt_external_interface
  # mac = each.value.mac

  network_interfaces = coalesce(each.value.network_interfaces, [])

  spice_server_enabled = coalesce(each.value.spice_server_enabled, false)

  cloudinit_use_user_data = coalesce(each.value.cloudinit_use_user_data, true)
  cloudinit_use_network_data = coalesce(each.value.cloudinit_use_network_data, true)
  cloudinit_custom_user_data = coalesce(each.value.cloudinit_custom_user_data, "# No custom user data\n")
  cloudinit_custom_network_data = coalesce(each.value.cloudinit_custom_network_data, "# No network user data\n")


  ansible_host   = each.value.ansible_host
  ansible_groups = each.value.ansible_groups
  ansible_user   = each.value.ansible_user
  ansible_ssh_pass = each.value.ansible_ssh_pass

}




resource "null_resource" "build-vyos-qcow2" {
  provisioner "local-exec" {
    command = <<-EOT

echo "Building VyOS qcow2 image"

# Exit if /tmp/vyos-1.5.0-cloud-init-10G-qemu.qcow2 already exists
if [ -f /tmp/vyos-1.5.0-cloud-init-10G-qemu.qcow2 ]; then
  exit 0
fi

# Remove any existing vyos-vm-images directory
rm -rf /tmp/vyos-vm-images

cd /tmp

git clone https://github.com/vyos/vyos-vm-images

cd vyos-vm-images

cat >> fix-build-qcow2.patch << EOF
diff --git a/roles/install-grub/tasks/main.yml b/roles/install-grub/tasks/main.yml
index 75de819..575dfbf 100644
--- a/roles/install-grub/tasks/main.yml
+++ b/roles/install-grub/tasks/main.yml
@@ -15,8 +15,6 @@
          mount --bind /proc {{ vyos_install_root }}/proc &&
          mount --bind /sys {{ vyos_install_root }}/sys &&
          mount --bind {{ vyos_write_root }} {{ vyos_install_root }}/boot 
-  args:
-    warn: no
 
 - name: Create efi directory
   become: true
EOF

git apply fix-build-qcow2.patch

ansible-playbook -b -e "ansible_become_password=${var.local_password}" qemu.yml -e disk_size=5 -e vyos_version=1.5.0 -e cloud_init=true -e cloud_init_ds=NoCloud -e "vyos_iso_url=https://github.com/vyos/vyos-rolling-nightly-builds/releases/download/1.5-rolling-202309250022/vyos-1.5-rolling-202309250022-amd64.iso" -b

echo "File built at /tmp/vyos-1.5.0-cloud-init-10G-qemu.qcow2"

EOT

  }
}