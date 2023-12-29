# Mailcow with FreeIPA and Keycloak
This is a test environment for Mailcow with FreeIPA and Keycloak. It is built with Terraform and Ansible.

# Terraform Ansible
This project also contains a POC of how I want to use modular standardised Terraform in combination with Ansible through my [diademiemi.vmutils](https://github.com/diademiemi/ansible_collection_diademiemi.vm_utils) Ansible collection.

The `diademiemi.vm_utils.terraform_inv_mgt` playbook is first ran to manage the Terraform inventory. This playbook is ran before any other playbook since this modifies the Terraform working directory for the Terraform inventory provider which is used in the second playbook.

The `diademiemi.vm_utils.terraform_vms` playbook is then ran to apply the Terraform configuration with a desired state of `create`, `destroy` or `recreate`. Read the documentation inside these playbooks for more information, [diademiemi.vm_utils/playbooks](https://github.com/diademiemi/ansible_collection_diademiemi.vm_utils/tree/main/playbooks).

The `diademiemi.vm_utils.terraform_dns` playbook is ran then to take the output from `terraform_vms` and apply it into a desired DNS provider. This playbook is ran after `terraform_vms` since it requires the output from `terraform_vms` to run.

# Terraform Structure
```
Project
├── ... # Ansible Code, etc
└── Terraform
    ├── Infra
    │   ├── Hetzner
    │   │   └── Vars
    │   │       └── {dev,test,acc,prod}.tfvars
    │   ├── Libvirt
    │   |   └── Vars
    │   |       └── {dev,test,acc,prod}.tfvars
    │   └── ... # Other providers
    └── DNS
        ├── DigitalOcean # Vars injected through Ansible
        ├── CloudFlare   # Vars injected through Ansible
        └── ... # Other providers

```

Infrastructure provider is selected with the `vm_utils_terraform_provider` variable. DNS provider is selected with the `vm_utils_terraform_dns_provider` variable. These variables are set in the Ansible inventory. 

The Terraform vars are selected with the `vm_utils_terraform_env` variable, extra variables can be set by setting the `TF_VAR_<var_name>` environment variable.

State is managed in different Terraform workspaces, one for each environment. The state is named after the provider and environment, e.g. `hetzner-dev` or `libvirt-prod`. The state name for the DNS is the name from the infra, to ensure these do not collide when the same DNS provider is used for multiple infrastructures.

The domain can be overriden with Ansible by setting the variable `new_domain`. This is useful for this specific test case since I want to be able to change the domain for the IPA server.

# Prerequisites

## Ansible Galaxy Requirements
```bash
ansible-galaxy install -r requirements.yml
```

## Hetzner (Infra)
```bash
export TF_VAR_hcloud_api_token="YOUR_API_TOKEN"
```

## Libvirt (Infra)
A running libvirt Daemon accessible over `TF_VAR_libvirt_uri` is required.
```bash
export TF_VAR_libvirt_uri="qemu:///system"  # This is the default value
```

## DigitalOcean (DNS & Infra)
```bash
export TF_VAR_digitalocean_api_token="YOUR_API_TOKEN"

export TF_VAR_digitalocean_domain_id="ZONE_ID"
# OR
export TF_VAR_digitalocean_domain="DOMAIN_NAME"
```

## Cloudflare (DNS)
```bash
export TF_VAR_cloudflare_api_token="YOUR_API_TOKEN"

export TF_VAR_cloudflare_domain_id="ZONE_ID"
# OR
export TF_VAR_cloudflare_domain_="DOMAIN_NAME"
```

## Selection
Set desired variables in `inventories/<env>/host_vars/localhost.yml`

`vm_utils_terraform_env` is the name of the environment, e.g. `dev`. This will be used to select the correct Terraform workspace.

`vm_utils_terraform_provider` is the name of the provider, e.g. `hetzner`. This will be used to select the correct Terraform infra directory and workspace.

`vm_utils_terraform_dns_provider` is the name of the DNS provider, e.g. `cloudflare`. This will be used to select the correct Terraform DNS directory.

Example `inventories/dev/host_vars/localhost.yml`:
```yaml
vm_utils_terraform_env: dev
vm_utils_terraform_provider: hetzner
vm_utils_terraform_dns_provider: digitalocean

## Example for Cloudflare DNS with additional vars to enable proxying and set TTL

# vm_utils_terraform_dns_additional_vars:
#   cloudflare_default_proxied: 'true'  # Terraform requires string values for booleans
#   cloudflare_default_ttl: 1

## Can also be set with export TF_VAR_cloudflare_default_proxied="true", etc.
```
# Terraform Usage
```bash
export TF_VAR_default_domain=dev.example.com

# Run Terraform playbook and create infrastructure
ansible-playbook -i inventories/dev playbooks/terraform.yml 

# Run Terraform playbook and destroy infrastructure
ansible-playbook -i inventories/dev playbooks/terraform.yml -e state=destroy

# Run Terraform playbook and recreate infrastructure
ansible-playbook -i inventories/dev playbooks/terraform.yml -e state=recreate
```

# Deploying
```bash
ansible-playbook -i inventories/dev playbooks/deploy.yml \
    -e new_domain="example.com" \
    -e ipa_domain="example.com" \
    -e keycloak_domain="example.com" \
    -e ipaadmin_password="admin" \
    -e keycloak_quarkus_admin_pass="admin"

```