# Configure the OpenStack Provider
provider "openstack" {
  version     = "~> 1.10"
  user_name   = "${var.username}"
  tenant_name = "${var.tenantname}"
  password    = "${var.password}"
  auth_url    = "${var.openstack_auth_url}"
  region      = "RegionOne"
  domain_name = "Default"
}
provider "null" {
  version = "~> 1.0"
}
provider "aws" {
  version     = "~> 1.39"
  region      = "${var.aws_region}"
  access_key  = "${var.access_key}"
  secret_key  = "${var.secret_key}"
}

// Configure the Google Cloud provider
provider "google" {
  version     = "~> 1.19"
  credentials = "${file(var.gcp_credentials_json)}"
  project     = "${var.gcp_projectname}"
  region      = "${var.aws_region}"
}



# OpenStack
module "hdp-master" {
  source                = "../../modules/nodegroups/openstack"
  host_group            = "hdp-master"
  hostname              = "cluster-os-m"
  domainsuffix          = "scalhive.com"
  nodescount            = 0
  flavor                = "c4.4xlarge" #TODO: change
  image                 = "CentOS-7.4"
  network_name          = "${var.network_name}"
  admin_username        = "centos"
  keyname               = "${var.openstack_keypair}"
  private_key           = "~/.ssh/big-data-sandbox.pem"
  enable_persist_volume = true
  aws_zone_id           = "${var.aws_zone_id}"
  system_volume_size    = 100
  persist_volume_size   = 30
  sec_groups            = ["default","local-network"]
  enable_floating_ip    = false
}

module "hdp-slave" {
  source                = "../../modules/nodegroups/openstack"
  host_group            = "hdp-slave"
  hostname              = "cluster-os-s"
  domainsuffix          = "scalhive.com"
  nodescount            = 2
  flavor                = "c4.2xlarge"
  image                 = "CentOS-7.4"
  network_name          = "${var.network_name}"
  admin_username        = "centos"
  keyname               = "${var.openstack_keypair}"
  private_key           = "~/.ssh/big-data-sandbox.pem"
  enable_persist_volume = true
  aws_zone_id           = "${var.aws_zone_id}"
  system_volume_size    = 100
  persist_volume_size   = 20
  sec_groups            = ["default","local-network"]
}

# GCP
module "gcp-hdp-master" {
  source                = "../../modules/nodegroups/gcp"
  host_group            = "hdp-master"
  hostname              = "cluster-gcp-m"
  domainsuffix          = "scalhive.com"
  nodescount            = 1
  machine_type          = "n1-standard-4" #machine type
  zone                  = "europe-west3-b"
  image                 = "centos-7-v20181011"
  gcp_projectname       = "${var.gcp_projectname}"
  network_name          = "${var.gcp_network_name}"
  admin_username        = "centos"
  private_key           = "~/.ssh/big-data-sandbox.pem"
  public_key            = "~/.ssh/big-data-sandbox.pub"
  enable_persist_volume = true
  aws_zone_id           = "${var.aws_zone_id}"
  persist_volume_size   = 30
}

module "gcp-hdp-slave" {
  source                = "../../modules/nodegroups/gcp"
  host_group            = "hdp-slave"
  hostname              = "cluster-gcp-s"
  domainsuffix          = "scalhive.com"
  nodescount            = 2
  machine_type          = "n1-standard-4" #machine type
  zone                  = "europe-west3-b"
  image                 = "centos-7-v20181011"
  gcp_projectname       = "${var.gcp_projectname}"
  network_name          = "${var.gcp_network_name}"
  admin_username        = "centos"
  private_key           = "~/.ssh/big-data-sandbox.pem"
  public_key            = "~/.ssh/big-data-sandbox.pub"
  enable_persist_volume = true
  aws_zone_id           = "${var.aws_zone_id}"
  persist_volume_size   = 30
}
module "gcp-hdp-edge" {
  source                = "../../modules/nodegroups/gcp"
  host_group            = "hdp-edge"
  hostname              = "cluster-gcp-e"
  domainsuffix          = "scalhive.com"
  nodescount            = 1
  machine_type          = "n1-standard-4" #machine type
  zone                  = "europe-west3-b"
  image                 = "centos-7-v20181011"
  gcp_projectname       = "${var.gcp_projectname}"
  network_name          = "${var.gcp_network_name}"
  admin_username        = "centos"
  private_key           = "~/.ssh/big-data-sandbox.pem"
  public_key            = "~/.ssh/big-data-sandbox.pub"
  enable_persist_volume = true
  aws_zone_id           = "${var.aws_zone_id}"
  persist_volume_size   = 30
}

# GCP DB PG
module "gcp-postgres" {
  source                = "../../modules/services/db/gcp-sql"
  enable_db             = false
  # https://cloud.google.com/sql/pricing
  db_machine_type       = "db-custom-1-3840"
  db_user_password      = "${var.db_password}"
  db_name               = "${var.db_name}"
  aws_zone_id           = "${var.aws_zone_id}"
  hostname              = "cluster-gcp-db"
  domainsuffix          = "scalhive.com"
}


resource "null_resource" "create_inventory" {
  depends_on = ["module.hdp-edge", "module.hdp-master", "module.hdp-slave", "module.gcp-hdp-master", "module.gcp-hdp-slave", "module.gcp-hdp-edge"]

  provisioner "local-exec" {
    when = "create"
    command = "echo '${module.hdp-edge.nodetype}${module.hdp-edge.static_inventory}${module.gcp-hdp-edge.static_inventory}${module.hdp-master.nodetype}${module.hdp-master.static_inventory}${module.gcp-hdp-master.static_inventory}${module.hdp-slave.nodetype}${module.hdp-slave.static_inventory}${module.gcp-hdp-slave.static_inventory}' > ../../../inventory/static"
    }

}