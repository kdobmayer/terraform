resource "aws_vpc" "test" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  vpc_id            = "${aws_vpc.test.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.test.cidr_block, 8, count.index + 1)}"
  availability_zone = "${element(local.zones, count.index)}"
  count             = "${length(local.zones)}"
}

resource "aws_subnet" "private" {
  vpc_id            = "${aws_vpc.test.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.test.cidr_block, 8, count.index + 11)}"
  availability_zone = "${element(local.zones, count.index)}"
  count             = "${length(local.zones)}"
}

resource "aws_internet_gateway" "test" {
  vpc_id = "${aws_vpc.test.id}"
}

resource "aws_eip" "nat" {
  vpc   = true
  count = "${length(local.zones)}"
}

resource "aws_nat_gateway" "test" {
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  count         = "${length(local.zones)}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.test.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.test.*.id, count.index)}"
  }

  count = "${length(local.zones)}"
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
  count          = "${length(local.zones)}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.test.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.test.id}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
  count          = "${length(local.zones)}"
}
