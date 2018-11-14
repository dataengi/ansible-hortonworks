variable "enable_db" {
  default = 0
  description = "enable DB in GCP"
}


#https://cloud.google.com/compute/docs/machine-types
variable "db_machine_type" {
  default = "n1-standard-1"
}

variable "db_disk_type" {
  default = "PD_SSD"
}

variable "db_disk_size" {
  default = "20"
}

variable "db_name" {
}


variable "db_user_name" {
  type = "string"
  default = "postgres"
}

variable "db_user_password" {
  type = "string"
}

variable "db_access_hostname" {
  type = "string"
  default = "*"
}

variable "aws_zone_id" {}

variable "domainsuffix" {}

variable "hostname" {
  default = "cluster-gcp-db"
}

