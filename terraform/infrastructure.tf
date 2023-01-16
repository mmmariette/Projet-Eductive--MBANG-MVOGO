## Une clef SSH par région

# Une clef SSH pour la région GRA11
resource "openstack_compute_keypair_v2" "keypair_gra11" {
  provider   = openstack.ovh
  name       = "sshkey_${var.student_id}"
  public_key = file("~/.ssh/id_rsa.pub")
  region     = var.region.gra
}

# Une clef SSH pour la région SBG5
resource "openstack_compute_keypair_v2" "keypair_sbg5" {
  provider   = openstack.ovh
  name       = "sshkey_${var.student_id}"
  public_key = file("~/.ssh/id_rsa.pub")
  region     = var.region.sbg
}

## Vrack Configs

# Vrack Réseau
resource "ovh_cloud_project_network_private" "network" {
  service_name = var.service_name
  name         = "private_network_${var.student_id}"
  regions      = values(var.region)
  provider     = ovh.ovh
  vlan_id      = var.vlan_id
}

# Vrack Subnet GRA11
resource "ovh_cloud_project_network_private_subnet" "subnet_gra11" {
  service_name = var.service_name
  network_id   = ovh_cloud_project_network_private.network.id
  start        = var.vlan_dhcp_start
  end          = var.vlan_dhcp_end
  network      = var.vlan_dhcp_network
  region       = var.region.gra
  provider     = ovh.ovh
  no_gateway   = true
}

# Vrack Subnet SBG5
resource "ovh_cloud_project_network_private_subnet" "subnet_sbg5" {
  service_name = var.service_name
  network_id   = ovh_cloud_project_network_private.network.id
  start        = var.vlan_dhcp_start
  end          = var.vlan_dhcp_end
  network      = var.vlan_dhcp_network
  region       = var.region.sbg
  provider     = ovh.ovh
  no_gateway   = true
}

## Instances

# Front instance à GRA11
resource "openstack_compute_instance_v2" "front_end" {
  name        = "front_${var.student_id}"
  provider    = openstack.ovh
  image_name  = var.instance.image_name
  flavor_name = var.instance.flavor_name
  region      = var.region.gra
  key_pair    = openstack_compute_keypair_v2.keypair_gra11.name

  # Public network
  network {
    name = "Ext-Net"
  }

  # vrack
  network {
    name        = ovh_cloud_project_network_private.network.name
    fixed_ip_v4 = "192.168.${var.vlan_id}.254"
  }
}

# GRA11 backend instance(s)
resource "openstack_compute_instance_v2" "gra_backends" {
  count       = var.gra_backends
  name        = "backend_${var.student_id}_gra_${count.index + 1}"
  provider    = openstack.ovh
  image_name  = var.instance.image_name
  flavor_name = var.instance.flavor_name
  region      = var.region.gra
  key_pair    = openstack_compute_keypair_v2.keypair_gra11.name

  network {
    name = "Ext-Net"
  }

  network {
    name        = ovh_cloud_project_network_private.network.name
    fixed_ip_v4 = "192.168.${var.vlan_id}.${count.index + 1}"
  }
  depends_on = [ovh_cloud_project_network_private_subnet.subnet_gra11]
}

# SBG5 backend instance(s)
resource "openstack_compute_instance_v2" "sbg_backends" {
  count       = var.sbg_backends
  name        = "backend_${var.student_id}_sbg_${count.index + 1}"
  provider    = openstack.ovh
  image_name  = var.instance.image_name
  flavor_name = var.instance.flavor_name
  region      = var.region.sbg
  key_pair    = openstack_compute_keypair_v2.keypair_sbg5.name

  network {
    name = "Ext-Net"
  }

  network {
    name        = ovh_cloud_project_network_private.network.name
    fixed_ip_v4 = "192.168.${var.vlan_id}.${count.index + 101}"
  }

  depends_on = [ovh_cloud_project_network_private_subnet.subnet_sbg5]
}

## Services Managés

resource "ovh_cloud_project_database" "db_eductive03" {
  service_name = var.service_name
  description  = "my_db_${var.student_id}_${var.service_db.region}"
  engine       = var.service_db.engine
  version      = var.service_db.version
  plan         = var.service_db.plan
  flavor       = var.service_db.flavor
  nodes {
    region = var.service_db.region
  }
}

resource "ovh_cloud_project_database_user" "eductive03" {
  service_name = ovh_cloud_project_database.db_eductive03.service_name
  engine       = ovh_cloud_project_database.db_eductive03.engine
  cluster_id   = ovh_cloud_project_database.db_eductive03.id
  name         = var.student_id
}

resource "ovh_cloud_project_database_database" "database" {
  service_name = ovh_cloud_project_database.db_eductive03.service_name
  engine       = ovh_cloud_project_database.db_eductive03.engine
  cluster_id   = ovh_cloud_project_database.db_eductive03.id
  name         = "db_${var.student_id}"
}

resource "ovh_cloud_project_database_ip_restriction" "iprestriction" {
  service_name = ovh_cloud_project_database.db_eductive03.service_name
  engine       = ovh_cloud_project_database.db_eductive03.engine
  cluster_id   = ovh_cloud_project_database.db_eductive03.id
  ip           = var.vlan_dhcp_network
}

## Inventaire
resource "local_file" "inventory" {
  filename = "../ansible/inventory.yml" # ouput filename
  content = templatefile("templates/inventory.tmpl",
    {
      sbg_backends = [for k, p in openstack_compute_instance_v2.sbg_backends : p.access_ip_v4],
      gra_backends = [for k, p in openstack_compute_instance_v2.gra_backends : p.access_ip_v4],
      front_end    = openstack_compute_instance_v2.front_end.access_ip_v4,
      service_db   = ovh_cloud_project_database_database.database.name
    }
  )
}
