terraform {
  required_version = ">= 1.2.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.49.0"
    }
    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.26.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.3.0"
    }
  }
}

# Configure le fournisseur OpenStack hébergé par OVHcloud
provider "openstack" {
  auth_url = "https://auth.cloud.ovh.net/v3/"
  alias    = "ovh"
}

provider "ovh" {
  alias    = "ovh"
  endpoint = "ovh-eu"
}
