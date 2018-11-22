variable "nodescount" {
  description = "number of nodes"
}

variable "gcp_projectname" {
  description = "Name of GCP project"
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

variable "image" {
  default = "centos-7-v20181011"
}

variable "admin_username" {}

variable "machine_type" {
  default = "n1-standard-4"
}

variable "host_group" {
  description = "group of hosts master|slave|node"
}

variable "hostname" {}

variable "domainsuffix" {}

variable "aws_zone_id" {}

variable zone {
  type = "string"
  default = "europe-west3-b"
}