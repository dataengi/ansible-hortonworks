resource "openstack_blockstorage_volume_v2" "persisit_volume" {
  count = "${var.enable_persist_volume ? var.nodescount : 0}"
  name = "${format("${var.host_group}-hdfs-%02d", count.index+1)}"
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

data "openstack_images_image_v2" "osimage" {
  name = "${var.image}"
  most_recent = true
  provider = "openstack"
}


locals {
  created_nodes = "%s ansible_host=%s ansible_user=${var.admin_username} ansible_ssh_private_key_file=\"${var.private_key}\"\n"
}


resource "openstack_compute_instance_v2" "node" {
  //stop_before_destroy = true

  count = "${var.nodescount}"
  name = "${format("${var.hostname}-%02d.${var.domainsuffix}", count.index+1)}"
  image_name = "${data.openstack_images_image_v2.osimage.name}"
  key_pair = "${var.keyname}" # openstack key_pair
  flavor_name = "${var.flavor}"
  security_groups = [
    "default",
    "local-network"]

  block_device {
    uuid = "${data.openstack_images_image_v2.osimage.id}"
    source_type = "image"
    destination_type = "local"
    boot_index = 0
    delete_on_termination = true
    volume_size = 100
  }
  network = {
    name = "${var.network_name}"
  }
}

resource "null_resource" "va" {
  depends_on = ["openstack_blockstorage_volume_v2.persisit_volume","openstack_compute_instance_v2.node","openstack_compute_volume_attach_v2.va"]
  count = "${var.enable_persist_volume ? var.nodescount : 0}"

  # custom username to connect
  connection {
    user = "${var.admin_username}"
    private_key = "${file("${var.private_key}")}"
    host = "${element(openstack_compute_instance_v2.node.*.access_ip_v4, count.index)}"
  }

 provisioner "local-exec" {
    when = "create"
    command = "sleep 20;  ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key '${var.private_key}' -i '${element(openstack_compute_instance_v2.node.*.access_ip_v4, count.index)},' ${path.module}/create_fs.yml"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "sleep 10;  ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key ~/datalake/big-data-sandbox.pem -i '${element(openstack_compute_instance_v2.node.*.access_ip_v4, count.index)},' ${path.module}/unmount_fs.yml; sleep 20"
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