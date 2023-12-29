variable "network_name" {
  type    = string
  default = ""
}

variable "network_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "network_zone" {
  type    = string
  default = "eu-central"
}