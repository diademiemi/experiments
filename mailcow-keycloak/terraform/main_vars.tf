variable "libvirt_uri" {
  type    = string
  default = "qemu:///system"
}

variable "domain" {
  type    = string
  default = ""
}

variable "network" {
  type    = string
  default = ""
}

variable "network_name" {
  type    = string
  default = ""
}

variable "network_mode" {
  type    = string
  default = ""
}

variable "libvirt_pool" {
  type    = string
  default = "default"
}

variable "local_password" {
  type    = string
  description = "Password for the local system, needed to build the VyOS qcow2 image"
  sensitive = true
}