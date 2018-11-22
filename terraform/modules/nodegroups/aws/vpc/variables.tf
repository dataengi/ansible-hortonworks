variable "nodescount" {
  description = "number of nodes"
}

variable "enable_persist_volume" {
  default = false
}

variable "persist_volume_size" {
  description = "size of persistance volumes"
  default = 2
}

variable "network_name" {}

variable "private_key" {}

variable "public_key" {}

variable "aws_centos_ami" {
  //  CentOS Linux 7 1801_01 2018-Jan-14 us-east-2 ami-e1496384 x86_64 HVM EBS
  default = "ami-e1496384"
}

variable "aws_region" {
  default = "us-east-2"
}

variable "admin_username" {}

variable "machine_type" {
  default = "t2.xlarge"
}

variable "host_group" {
  description = "group of hosts master|slave|node"
}

variable "hostname" {}

variable "domainsuffix" {}

variable "aws_zone_id" {
  default = "us-east-2a"
}
