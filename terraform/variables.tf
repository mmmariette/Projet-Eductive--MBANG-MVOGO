# STUDENT_ID
variable "student_id" {
  type    = string
  default = "eductive03"
}

variable "service_name" {
  type = string
}

# Instance configs
variable "instance" {
  type = map(string)
  default = {
    flavor_name = "s1-2"
    image_name  = "Debian 11"
  }
}

variable "gra_backends" {
  default = 1
  type    = number
}

variable "sbg_backends" {
  default = 1
  type    = number
}

# Vrack configs 
variable "region" {
  type = map(string)
  default = {
    "gra" = "GRA11"
    "sbg" = "SBG5"
  }
}

variable "vlan_id" {
  type    = number
  default = 03
}

variable "vlan_dhcp_start" {
  type    = string
  default = "192.168.03.100"
}

variable "vlan_dhcp_end" {
  type    = string
  default = "192.168.03.200"
}

variable "vlan_dhcp_network" {
  type    = string
  default = "192.168.03.0/24"
}

# database configs
variable "service_db" {
  type = map(string)
  default = {
    plan    = "essential"
    flavor  = "db1-4"
    version = "8"
    region  = "GRA"
    engine  = "mysql"
  }
}
