resource "aws_security_group" "ws" {
  name                   = "testing-ws"
  description            = "web server security group"
  vpc_id                 = "${aws_vpc.test.id}"
  revoke_rules_on_delete = true
  tags                   = "${map("Name", "terraform")}"
}

resource "aws_security_group_rule" "ws_from_http" {
  security_group_id = "${aws_security_group.ws.id}"
  description       = "allow inbound HTTP access to the web servers from any adress."
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ws_from_https" {
  security_group_id = "${aws_security_group.ws.id}"
  description       = "allow inbound HTTPS access to the web servers from any address."
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ws_from_ssh" {
  security_group_id = "${aws_security_group.ws.id}"
  description       = "allow inbound SSH access from your home network."
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["${chomp(data.http.my_ip.body)}/32"]
}

resource "aws_security_group_rule" "ws_to_http" {
  security_group_id = "${aws_security_group.ws.id}"
  description       = "allow outbound HTTP access to any address."
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ws_to_https" {
  security_group_id = "${aws_security_group.ws.id}"
  description       = "allow outbound HTTPS access to any address."
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ws_to_db" {
  security_group_id        = "${aws_security_group.ws.id}"
  description              = "allow outbound MySQL access to the database servers."
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = "${aws_security_group.db.id}"
}

resource "aws_instance" "web" {
  ami                         = "${data.aws_ami.web.id}"
  instance_type               = "t2.micro"
  key_name                    = "${aws_key_pair.test.id}"
  vpc_security_group_ids      = ["${aws_security_group.ws.id}"]
  associate_public_ip_address = true
  subnet_id                   = "${element(aws_subnet.public.*.id, count.index)}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags = "${map("Name", "terraform")}"

  count = "${length(local.zones)}"

  connection {
    type = "ssh"
    user = "ec2-user"
  }

  provisioner "remote-exec" {
    inline = [
      "docker run -d --network=host --name=demo -p 80:80 <image> <command> --host ${replace(aws_db_instance.test.endpoint, ":3306", "")} --user user --passwd pass --dbname db",
    ]
  }
}
