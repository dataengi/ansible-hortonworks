resource "google_sql_database_instance" "master" {
  count = "${var.enable_db}"
  name = "${format("${var.hostname}-%02d", count.index+1)}"
  database_version = "POSTGRES_9_6"
  region = "europe-west1"
  settings {
    tier = "${var.db_machine_type}"
    disk_type = "${var.db_disk_type}"
    disk_size = "${var.db_disk_size}"
  }
}

resource "google_sql_database" "database" {
  count = "${var.enable_db}"
  name      = "${var.db_name}"
  instance  = "${google_sql_database_instance.master.0.name}"
}

resource "google_sql_user" "users" {
  count = "${var.enable_db}"
  name     = "${var.db_user_name}"
  instance = "${google_sql_database_instance.master.0.name}"
  host     = "${var.db_access_hostname}"
  password = "${var.db_user_password}"
}
# gcloud sql connect gcp-cluster-db2 --user=postgres

resource "aws_route53_record" "nodegroups-dns-records" {
  count = "${var.enable_db}"
  zone_id = "${var.aws_zone_id}"
  name = "${format("${var.hostname}-%02d.${var.domainsuffix}", count.index+1)}"
  //name = "${element(format("${google_sql_database_instance.master.*.name}.${var.domainsuffix}"), count.index)}" #"${format("${google_sql_database_instance.master.name}.${var.domainsuffix}")}"
  type = "A"
  ttl = "300"
  records = ["${element(google_sql_database_instance.master.*.first_ip_address, count.index)}"] # ["${element(google_sql_database_instance.master.*.ip_address, count.index)}"]
}