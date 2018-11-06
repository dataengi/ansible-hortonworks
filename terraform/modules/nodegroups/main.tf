/**
resource "openstack_blockstorage_volume_v2" "persisit_volume" {
  count = "${var.enable_persist_volume ? var.nodescount : 0}"
  name = "${format("${var.hostname}-hdfs-%02d", count.index+1)}"
  size = "${var.persist_volume_size}"
  description = "${format("volume for HDFS on node ${var.host_group}-hdfs-%02d", count.index+1)}"
  provider = "openstack"

  lifecycle {
    prevent_destroy = false
  }
}

resource "openstack_compute_volume_attach_v2" "va" {
  count = "${var.enable_persist_volume ? var.nodescount : 0}"
  volume_id = "${element(openstack_blockstorage_volume_v2.persisit_volume.*.id, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.node.*.id, count.index)}"
}
*/
data "openstack_images_image_v2" "osimage" {
  name = "${var.image}"
  most_recent = true
  provider = "openstack"
}


locals {
  created_nodes = "%s ansible_host=%s ansible_user=${var.admin_username} ansible_ssh_private_key_file=\"${var.private_key}\"\n"
}

resource "openstack_compute_floatingip_v2" "float_ip" {
  count = "${var.enable_floating_ip ? var.nodescount : 0}"
  pool  = "external_network"
}

resource "openstack_compute_floatingip_associate_v2" "floatingip" {
  count = "${var.enable_floating_ip ? var.nodescount : 0}"
  floating_ip = "${element(openstack_compute_floatingip_v2.float_ip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.node.*.id, count.index)}"
}


resource "openstack_compute_instance_v2" "node" {
  //stop_before_destroy = true

  count = "${var.nodescount}"
  name = "${format("${var.hostname}-%02d.${var.domainsuffix}", count.index+1)}"
  image_name = "${data.openstack_images_image_v2.osimage.name}"
  key_pair = "${var.keyname}" # openstack key_pair
  flavor_name = "${var.flavor}"
  security_groups = "${var.sec_groups}"

  block_device {
    uuid = "${data.openstack_images_image_v2.osimage.id}"
    source_type = "image"
    destination_type = "volume"
    boot_index = 0
    delete_on_termination = true
    volume_size = "${var.system_volume_size}"
  }

  block_device {
    source_type = "blank"
    destination_type = "volume"
    volume_size = "${var.enable_persist_volume ? var.persist_volume_size : 0}"
    delete_on_termination = true
    boot_index = -1
  }

  network = {
    name = "${var.network_name}"
  }
}

resource "null_resource" "va" {
  //depends_on = ["openstack_blockstorage_volume_v2.persisit_volume","openstack_compute_instance_v2.node","openstack_compute_volume_attach_v2.va"]
  depends_on = ["openstack_compute_instance_v2.node"]
  count = "${var.enable_persist_volume ? var.nodescount : 0}"

  # custom username to connect
  connection {
    user = "${var.admin_username}"
    private_key = "${file("${var.private_key}")}"
    host = "${element(openstack_compute_instance_v2.node.*.access_ip_v4, count.index)}"
  }

 provisioner "local-exec" {
    when = "create"
    command = "sleep 30;  ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key '${var.private_key}' -i '${element(openstack_compute_instance_v2.node.*.access_ip_v4, count.index)},' ${path.module}/create_fs.yml"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "sleep 30;  ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key ~/datalake/big-data-sandbox.pem -i '${element(openstack_compute_instance_v2.node.*.access_ip_v4, count.index)},' ${path.module}/unmount_fs.yml; sleep 20"
  }
}

resource "aws_route53_record" "nodegroups-dns-records" {
  count = "${var.nodescount}"

  zone_id = "${var.aws_zone_id}"
  name = "${element(openstack_compute_instance_v2.node.*.name, count.index)}"
  type = "A"
  ttl = "300"
  records = ["${element(openstack_compute_instance_v2.node.*.access_ip_v4, count.index)}"]
}

resource "aws_route53_record" "nodegroups-reverse-dns-records" {
  count = "${var.nodescount}"

  zone_id = "${var.aws_reverse_zone_id}"
//  name = "${element(openstack_compute_instance_v2.node.*.access_ip_v4, count.index)}" //    IP.0.224.10.in-addr.arpa
  name = "${format("%s.%s.%s.%s.in-addr.arpa",
                    element(split(".", format("%s", element(openstack_compute_instance_v2.node.*.access_ip_v4, count.index))), 3),
                    element(split(".", format("%s", element(openstack_compute_instance_v2.node.*.access_ip_v4, count.index))), 2),
                    element(split(".", format("%s", element(openstack_compute_instance_v2.node.*.access_ip_v4, count.index))), 1),
                    element(split(".", format("%s", element(openstack_compute_instance_v2.node.*.access_ip_v4, count.index))), 0))
                    }"
  type = "PTR"
  ttl = "30"
  records = ["${element(openstack_compute_instance_v2.node.*.name, count.index)}"]  // NAME
}