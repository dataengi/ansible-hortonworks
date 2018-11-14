variable "username" {
  description = "Openstack username"
}

variable "gcp_projectname" {}

variable "gcp_credentials_json" {
  type = "string"

}

variable "tenantname" {
  description = "The name of the Tenant (in terms of OStack tenant is project-name)"
}

variable "password" {
  description = "The password for the Tenant."
}

variable "openstack_auth_url" {
  description = "The endpoint url to connect to OpenStack."
}

variable "openstack_keypair" {
  description = "The keypair to be used."
}

variable "network_name" {
  description = "The network to be used."
}


variable "gcp_network_name" {
  description = "The network to be used in GCP."
}

variable "access_key" {
  description = "Access key"
}

variable "secret_key" {
  description = "Secret key"
}

variable "aws_region" {}

variable "aws_zone_id" {}

# dedicated DB
variable db_password {
  type = "string"
}

variable db_name {
  type = "string"
}
