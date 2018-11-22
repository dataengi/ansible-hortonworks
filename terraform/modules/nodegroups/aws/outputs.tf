output "public_subnet" {
  value = "${aws_subnet.public.id}"
}

output "private_subnet" {
  value = "${aws_subnet.private.id}"
}

output "dev_vpc" {
  value = "${aws_vpc.dev.id}"
}

output "auth_key" {
  value = "${aws_key_pair.auth.id}"
}


output "nodeips" {
  value = "${google_compute_instance.node.*.network_interface.0.address}"

}

output "nodenames" {
  value = "${google_compute_instance.node.*.name}"
}

output "nodetype" {
  value = "[${var.host_group}]\n"
}

output "static_inventory" {
//  value = "${join("", formatlist("%s ansible_host=%s ansible_user=%s ansible_ssh_private_key_file=%s\n",
//                                      google_compute_instance.default.*.name,
//                                      google_compute_instance.default.*.network_interface.0.access_config.0.nat_ip,
//                                      var.admin_username, var.private_key))}"

  value = "${join("", formatlist("%s ansible_host=%s ansible_user=%s ansible_ssh_private_key_file=%s\n",
                                      google_compute_instance.node.*.name,
                                      google_compute_instance.node.*.network_interface.0.address,
                                      var.admin_username, var.private_key))}"
}
