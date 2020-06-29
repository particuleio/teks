terraform {
  backend "s3" {
  }
}

provider "aws" {
  region  = var.aws["region"]
  version = "~> 2.41"
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.this[0].id
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.this[0].id
}

variable "aws" {
  type = any
}
