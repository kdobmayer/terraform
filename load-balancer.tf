resource "aws_security_group" "lb" {
  name                   = "testing-lb"
  description            = "load balancer security group"
  vpc_id                 = "${aws_vpc.test.id}"
  revoke_rules_on_delete = true
  tags                   = "${map("Name", "terraform")}"
}

resource "aws_security_group_rule" "lb_from_http" {
  security_group_id = "${aws_security_group.lb.id}"
  description       = "allow inbound HTTP access from any adress."
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "lb_to_http" {
  security_group_id = "${aws_security_group.lb.id}"
  description       = "allow outbound HTTP access to any adress."
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_elb" "test" {
  name                      = "terraform-load-balancer"
  cross_zone_load_balancing = true
  security_groups           = ["${aws_security_group.lb.id}"]
  subnets                   = ["${aws_subnet.public.*.id}"]
  instances                 = ["${aws_instance.web.*.id}"]

  listener {
    instance_protocol = "http"
    instance_port     = 80
    lb_protocol       = "http"
    lb_port           = 80
  }

  health_check {
    target              = "HTTP:80/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    timeout             = 5
  }
}
