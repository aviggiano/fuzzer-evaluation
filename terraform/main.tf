# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "security_group" {
  name   = "fuzzer-evaluation-sg-18"
  vpc_id = data.aws_vpc.default.id

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "ec2_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.security_group.id]
  user_data_replace_on_change = true

  for_each = tomap({
    for val in local.data :
    "${val.fuzzer}:${val.seed}:${val.mutant}" => val
  })

  key_name = var.ec2_instance_key_name

  user_data = templatefile("user_data.tftpl", {
    s3_bucket             = var.s3_bucket,
    aws_access_key_id     = var.aws_access_key_id,
    aws_secret_access_key = var.aws_access_key_secret,
    seed                  = each.value.seed,
    mutant                = each.value.mutant,
    fuzzer                = each.value.fuzzer,
  })
}
