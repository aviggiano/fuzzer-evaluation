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

resource "aws_instance" "ec2_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [data.aws_vpc.default.id]
  user_data_replace_on_change = true

  key_name = var.ec2_instance_key_name

  user_data = templatefile("user_data.tftpl", {
    s3_bucket             = var.s3_bucket,
    aws_access_key_id     = var.aws_access_key_id,
    aws_secret_access_key = var.aws_access_key_secret
  })
}
