# Specify the provider and access details
provider "aws" {
  region = "${var.aws_zone_id}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "dev" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = "true"
  enable_dns_hostnames = "true" # security ?
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.dev.id}"
}

# EIP associated w/ NAT GW
resource "aws_eip" "nat" {
  vpc = true
}

# Create NAT Gateway for instance on private network to get internet access
resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.public.id}"
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.dev.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.dev.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

# Grant the VPC internet access on its main route table
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.dev.id}"
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"

}

# Create a subnet to launch our instances into
resource "aws_subnet" "private" {
  vpc_id                  = "${aws_vpc.dev.id}"
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false
}

resource "aws_key_pair" "auth" {
  key_name   = "${lookup(var.private_key, var.aws_region)}"
  public_key = "${file(lookup(var.public_key, var.aws_region))}" // TODO: check public_key
}