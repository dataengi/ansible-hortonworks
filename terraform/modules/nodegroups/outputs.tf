output "nodeips" {
  value = "${openstack_compute_instance_v2.node.*.access_ip_v4}"
}

output "nodenames" {
  value = "${openstack_compute_instance_v2.node.*.name}"
}

output "nodetype" {
  value = "[${var.host_group}]\n"
}

output "static_inventory" {
  value = "${join("", formatlist("%s ansible_host=%s ansible_user=%s ansible_ssh_private_key_file=%s\n", openstack_compute_instance_v2.node.*.name, openstack_compute_instance_v2.node.*.access_ip_v4, var.admin_username, var.private_key))}"
}
