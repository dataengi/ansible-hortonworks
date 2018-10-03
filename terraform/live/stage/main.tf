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



module "hdp-master" {
  source                = "../../modules/nodes"
  host_group            = "hdp-master"
  nodescount            = 1
  flavor                = "t2.medium" #TODO: change
  image                 = "CentOS-7.4"
  network_name          = "${var.network_name}"
  admin_username        = "centos"
  keyname               = "${var.openstack_keypair}"
  private_key           = "~/.ssh/big-data-sandbox.pem" #TODO: get from OpenStack
  enable_persist_volume = true
  persist_volume_size   = 2
}

module "hdp-slave" {
  source                = "../../modules/nodes"
  host_group            = "hdp-slave"
  nodescount            = 1
  flavor                = "t2.medium"
  image                 = "CentOS-7.4"
  network_name          = "${var.network_name}"
  admin_username        = "centos"
  keyname               = "${var.openstack_keypair}"
  private_key           = "~/.ssh/big-data-sandbox.pem"
  enable_persist_volume = true
  persist_volume_size   = 2
}

module "hdp-edge" {
  source                = "../../modules/nodes"
  host_group            = "hdp-edge"
  nodescount            = 1
  flavor                = "t2.medium"
  image                 = "CentOS-7.4"
  network_name          = "${var.network_name}"
  admin_username        = "centos"
  keyname               = "${var.openstack_keypair}"
  private_key           = "~/.ssh/big-data-sandbox.pem"
  enable_persist_volume = false
  persist_volume_size   = 2
}


resource "null_resource" "create_inventory" {


  depends_on = ["module.hdp-edge", "module.hdp-master", "module.hdp-slave"]

  provisioner "local-exec" {
    when = "create"
    command = "echo '${module.hdp-edge.nodetype}${module.hdp-edge.static_inventory}${module.hdp-master.nodetype}${module.hdp-master.static_inventory}${module.hdp-slave.nodetype}${module.hdp-slave.static_inventory}' > ../../../inventory/static"
    }
}