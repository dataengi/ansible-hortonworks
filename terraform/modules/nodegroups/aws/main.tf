resource "google_compute_disk" "persisit_volume" {
  count = "${var.enable_persist_volume ? var.nodescount : 0}"
  name = "${format("${var.hostname}-hdfs-%02d", count.index+1)}"
  size = "${var.persist_volume_size}"
  description = "${format("volume for HDFS on node ${var.host_group}-hdfs-%02d", count.index+1)}"
  type = "pd-standard"
  zone = "${var.zone}"
  labels {
    environment = "hdfs"
  }
}

resource "google_compute_attached_disk" "va" {
  count = "${var.enable_persist_volume ? var.nodescount : 0}"
  disk = "${element(google_compute_disk.persisit_volume.*.self_link, count.index)}"
  instance = "${element(google_compute_instance.node.*.self_link, count.index)}"
}


data "google_compute_image" "osimage" {
  #https://cloud.google.com/compute/docs/images#os-compute-support
  family = "centos-7"
  project = "centos-cloud"
}

resource "google_compute_instance" "node" {
  count = "${var.nodescount}"
  name  = "${format("${var.hostname}-%02d", count.index+1)}"
  project = "${var.gcp_projectname}"


  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"

  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.osimage.self_link}"
      size = 40
      type = "pd-standard"
    }
  }

  metadata_startup_script = "sudo yum -y update; sudo yum install ntp; ${format("sudo hostnamectl set-hostname ${var.hostname}-%02d.${var.domainsuffix}", count.index+1)}; sudo systemctl start ntpd.service"



  metadata {
    sshKeys = "${var.admin_username}:${file(var.public_key)}"
  }

  network_interface {
//    network = "gcp-shared-network"
    subnetwork = "datalake"
    subnetwork_project = "admin-219614"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }
}


resource "null_resource" "va" {
  depends_on = ["google_compute_disk.persisit_volume","google_compute_instance.node","google_compute_attached_disk.va"]
  count = "${var.enable_persist_volume ? var.nodescount : 0}"

  # custom username to connect
  connection {
    user = "${var.admin_username}"
    private_key = "${file("${var.private_key}")}"
    host = "${element(google_compute_instance.node.*.network_interface.0.address, count.index)}"
  }

  provisioner "local-exec" {
    when = "create"
//    command = "sleep 20;  ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key '${var.private_key}' -i '${element(google_compute_instance.node.*.network_interface.0.access_config.0.assigned_nat_ip, count.index)},' ${path.module}/create_fs.yml"
    command = "sleep 20;  ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key '${var.private_key}' -i '${element(google_compute_instance.node.*.network_interface.0.address, count.index)},' ${path.module}/create_fs.yml"
  }

  provisioner "local-exec" {
    when = "destroy"
//    command = "sleep 10;  ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key '${var.private_key}' -i '${element(google_compute_instance.node.*.network_interface.0.access_config.0.assigned_nat_ip, count.index)},' ${path.module}/unmount_fs.yml; sleep 20"
    command = "sleep 10;  ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key '${var.private_key}' -i '${element(google_compute_instance.node.*.network_interface.0.address, count.index)},' ${path.module}/unmount_fs.yml; sleep 20"
  }
}


resource "aws_route53_record" "nodegroups-dns-records" {
  count = "${var.nodescount}"

  zone_id = "${var.aws_zone_id}"
  name = "${format("${var.hostname}-%02d.${var.domainsuffix}", count.index+1)}"
  type = "A"
  ttl = "300"
  records = ["${element(google_compute_instance.node.*.network_interface.0.address, count.index)}"]
}
