variable "region" {
  type        = string
  description = "AWS Region"
  default     = "us-east-1"
}

variable "s3_bucket" {
  type        = string
  description = "S3 Bucket name to store results"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
  default     = "m3.medium"
}

variable "ec2_instance_key_name" {
  type        = string
  description = "EC2 instance key name. Needs to be manually created first on the AWS console"
}

variable "ami_id" {
  type        = string
  description = "EC2 AMI ID"
}

variable "aws_access_key_id" {
  type        = string
  description = "AWS Access Key Id"
}

variable "aws_access_key_secret" {
  type        = string
  description = "AWS Access Key Secret"
}

locals {
  data = jsondecode(file("../data18.json"))
}
