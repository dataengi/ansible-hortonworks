output "invfile" {
  value = "${module.hdp-edge.nodetype}${module.gcp-hdp-master.static_inventory}${module.hdp-edge.static_inventory}${module.hdp-master.nodetype}${module.hdp-master.static_inventory}${module.hdp-slave.nodetype}${module.hdp-slave.static_inventory}"
  //value = "${module.hdp-master.nodetype}${module.hdp-master.static_inventory}${module.hdp-slave.nodetype}${module.hdp-slave.static_inventory}"
}
