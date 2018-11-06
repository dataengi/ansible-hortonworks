output "invfile" {
  value = "${module.hdp-master.nodetype}${module.hdp-master.static_inventory}${module.hdp-slave.nodetype}${module.hdp-slave.static_inventory}"
}
