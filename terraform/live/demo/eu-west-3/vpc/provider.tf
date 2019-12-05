provider "aws" {
  region  = var.aws["region"]
  version = "~> 2.41"
}

terraform {
  backend "s3" {
  }
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

variable "aws" {
  type = any
}
