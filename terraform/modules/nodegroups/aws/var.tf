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

// TODO: check vars below
variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "aws_ami" {
  description = "Ubuntu Server 14.04 LTS (HVM)"
  default     = "ami-09dc1267"
}

variable "aws_vpc_id" {
  default = "vpc-80e15be9"
}

variable "aws_public_subnet_id" {
  default = "subnet-6dbf7920"
}

variable "aws_private_subnet_id" {
  default = "subnet-6cbf7921"
}

variable "aws_key_name" {
  default     = "main"
  description = "Name of AWS key pair"
}

variable "aws_instance_type" {
  default     = "m4.large"
  description = "AWS instance type"
}

variable "ssh_private_key" {
  default = "secret"
}

variable "master_node_count" {
  default = 2
}

variable "slave_node_count" {
  default = 3
}

variable "admin_password" {
  default = "admin123"
}

variable "services_password" {
  default = "admin123"
}