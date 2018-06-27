terraform {
  backend "s3" {
    bucket = "terraform.kdobmayer"
    key    = "state/testing"
  }
}

provider "aws" {
  version = "~> 1.20"
}

data "http" "my_ip" {
  url = "http://icanhazip.com"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  zones = "${data.aws_availability_zones.available.names}"
}

resource "aws_key_pair" "test" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

data "aws_ami" "web" {
  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:Name"
    values = ["ami-name"]
  }

  most_recent = true
}
