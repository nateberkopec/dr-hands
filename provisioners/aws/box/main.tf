terraform {
  required_version = "~> 1.17"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.71.0"
    }
  }
}

variable "report" {
  type = string
  validation {
    condition     = can(regex("^ghsa-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}$", var.report))
    error_message = "report must be a lowercase GHSA ID."
  }
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "m7g.large"
}

variable "tailnet_auth_key" {
  type      = string
  sensitive = true
}

variable "ssh_public_key" {
  type = string
}

provider "aws" {
  default_tags {
    tags = {
      dr-hands = "box"
      report   = var.report
    }
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ec2_instance_type_offerings" "zones" {
  location_type = "availability-zone"
  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
  filter {
    name   = "availability-zone"
    values = data.aws_ec2_instance_type_offerings.zones.locations
  }
}

resource "aws_security_group" "box" {
  name   = "dr-hands-${var.report}"
  vpc_id = data.aws_vpc.default.id

  egress {
    description = "HTTPS for the package proxy and Tailscale DERP relays"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Direct Tailscale paths and STUN"
    protocol    = "udp"
    from_port   = 3478
    to_port     = 3478
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Direct Tailscale paths"
    protocol    = "udp"
    from_port   = 41641
    to_port     = 41641
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "box" {
  ami                                  = var.ami
  instance_type                        = var.instance_type
  subnet_id                            = sort(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids               = [aws_security_group.box.id]
  associate_public_ip_address          = true
  instance_initiated_shutdown_behavior = "terminate"

  user_data = templatefile("${path.module}/user-data.yaml", {
    hostname         = var.report
    tailnet_auth_key = var.tailnet_auth_key
    ssh_public_key   = var.ssh_public_key
  })

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 40
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "dr-hands-${var.report}"
  }

  lifecycle {
    ignore_changes = [metadata_options]
  }
}

output "instance_id" {
  value = aws_instance.box.id
}
