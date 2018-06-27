output "ip" {
  value = "${aws_elb.test.dns_name}"
}
