resource "aws_db_subnet_group" "test" {
  name        = "testing"
  description = "database security group"
  subnet_ids  = ["${aws_subnet.private.*.id}"]
}

resource "aws_security_group" "db" {
  name                   = "testing-db"
  vpc_id                 = "${aws_vpc.test.id}"
  revoke_rules_on_delete = true
}

resource "aws_security_group_rule" "db_from_ws" {
  security_group_id        = "${aws_security_group.db.id}"
  description              = "allow inbound MySQL Server access from the web servers."
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = "${aws_security_group.ws.id}"
}

resource "aws_security_group_rule" "db_to_http" {
  security_group_id = "${aws_security_group.db.id}"
  description       = "allow outbound HTTP access to the internet."
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "db_to_https" {
  security_group_id = "${aws_security_group.db.id}"
  description       = "allow outbound HTTPS access to the internet."
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_db_instance" "test" {
  identifier              = "terraform-mysql"
  instance_class          = "db.t2.micro"
  engine                  = "mysql"
  engine_version          = "5.7"
  storage_type            = "gp2"
  port                    = 3306
  allocated_storage       = 20
  backup_retention_period = 0
  monitoring_interval     = 0
  skip_final_snapshot     = true
  publicly_accessible     = false
  username                = "user"
  password                = "pass"
  name                    = "db"
  db_subnet_group_name    = "${aws_db_subnet_group.test.id}"
  vpc_security_group_ids  = ["${aws_security_group.db.id}"]
}
