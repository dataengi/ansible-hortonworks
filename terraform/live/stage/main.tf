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
  region      = "${var.aws_region}"
  access_key  = "${var.access_key}"
  secret_key  = "${var.secret_key}"
  version     = "~> 1.39"
}


module "hdp-master" {
  source                = "../../modules/nodegroups"
  host_group            = "hdp-masternode-01"
  hostname              = "cluster-os-m1"
  domainsuffix          = "scalhive.com"
  nodescount            = 1
  flavor                = "c4.4xlarge"
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


module "hdp-master2" {
  source                = "../../modules/nodegroups"
  host_group            = "hdp-masternode-02"
  hostname              = "cluster-os-m2"
  domainsuffix          = "scalhive.com"
  nodescount            = 1
  flavor                = "c4.4xlarge"
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
  source                = "../../modules/nodegroups"
  host_group            = "hdp-worker"
  hostname              = "cluster-os-s"
  domainsuffix          = "scalhive.com"
  nodescount            = 3
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

module "hdp-edge" {
  source                = "../../modules/nodegroups"
  host_group            = "hdp-management"
  hostname              = "cluster-os-e"
  domainsuffix          = "scalhive.com"
  nodescount            = 1
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


resource "null_resource" "create_inventory" {

  depends_on = ["module.hdp-edge", "module.hdp-master", "module.hdp-master2", "module.hdp-slave"]

  provisioner "local-exec" {
    when = "create"
    command = "echo '${module.hdp-edge.nodetype}${module.hdp-edge.static_inventory}${module.hdp-master.nodetype}${module.hdp-master.static_inventory}${module.hdp-master2.nodetype}${module.hdp-master2.static_inventory}${module.hdp-slave.nodetype}${module.hdp-slave.static_inventory}' > ../../../inventory/static"
    }
}