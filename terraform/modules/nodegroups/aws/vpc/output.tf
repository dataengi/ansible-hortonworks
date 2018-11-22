output "public_subnet" {
  value = "${aws_subnet.public.id}"
}

output "private_subnet" {
  value = "${aws_subnet.private.id}"
}

output "dev_vpc" {
  value = "${aws_vpc.dev.id}"
}

output "auth_key" {
  value = "${aws_key_pair.auth.id}"
}