resource "aws_security_group" "edge" {
  name        = "bastion-ssh"
  description = "Used in the SMS ssh"
  vpc_id      = "${var.aws_vpc_id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "internal" {
  name        = "vpc-internal"
  description = "Used in the internal"
  vpc_id      = "${var.aws_vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "bastion" {
  instance = "${aws_instance.bastion.id}"
  vpc      = true
}

resource "aws_instance" "bastion" {
  instance_type          = "t2.micro"
  subnet_id              = "${var.aws_public_subnet_id}"
  ami                    = "${var.aws_ami}"
  key_name               = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.edge.id}", "${aws_security_group.internal.id}"]

  root_block_device = {
    volume_type = "standard"
    volume_size = 50
  }

//  user_data = "${template_file.userdata.rendered}"

  # Instance tags
  tags {
    Name = "bastion"
  }
}

resource "aws_instance" "master" {
  instance_type          = "${var.aws_instance_type}"
  subnet_id              = "${var.aws_private_subnet_id}"
  ami                    = "${var.aws_ami}"
  key_name               = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.internal.id}"]
  count                  = "${var.master_node_count}"

  root_block_device = {
    volume_type = "standard"
    volume_size = 200
  }

  user_data ="${file("scripts/hdp_node_userdata.sh")}"

  # Instance tags
  tags {
    Name = "master"
  }
}

resource "aws_instance" "slave" {
  instance_type          = "${var.aws_instance_type}"
  subnet_id              = "${var.aws_private_subnet_id}"
  ami                    = "${var.aws_ami}"
  key_name               = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.internal.id}"]
  count                  = "${var.slave_node_count}"

  root_block_device = {
    volume_type = "standard"
    volume_size = 50
  }

  ebs_block_device {
    device_name = "/dev/xvdf"
    volume_type = "standard"
    volume_size = 200
  }

  ebs_block_device {
    device_name = "/dev/xvdg"
    volume_type = "standard"
    volume_size = 200
  }

  ebs_block_device {
    device_name = "/dev/xvdh"
    volume_type = "standard"
    volume_size = 200
  }

  user_data ="${file("scripts/hdp_node_userdata.sh")}"

  # Instance tags
  tags {
    Name = "slave"
  }
}



resource "google_compute_disk" "persisit_volume" {
  count = "${var.enable_persist_volume ? var.nodescount : 0}"
  name = "${format("${var.hostname}-hdfs-%02d", count.index+1)}"
  size = "${var.persist_volume_size}"
  description = "${format("volume for HDFS on node ${var.host_group}-hdfs-%02d", count.index+1)}"
  type = "pd-standard"
//  zone = "${var.zone}"
  labels {
    environment = "hdfs"
  }
}
# the CentOS AMI should be HVM: https://wiki.centos.org/Cloud/AWS
# (make sure the AMI is for the proper aws region)


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
//  project = "${var.gcp_projectname}"


  machine_type = "${var.machine_type}"
//  zone         = "${var.zone}"

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
