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

variable "keyname" {} # openstack_keypair

variable "private_key" {}

variable "image" {
  default = "CentOS-7.4"
}

variable "admin_username" {}

variable "flavor" {
  default = "t2.medium"
}

variable "host_group" {
  description = "group of hosts master|slave|node"
}

variable "hostname" {}

variable "domainsuffix" {}

variable "aws_zone_id" {}
