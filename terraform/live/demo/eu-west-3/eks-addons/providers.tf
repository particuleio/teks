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
  version                = "1.10"
}

provider "helm" {
  version = "~> 1.0"
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    load_config_file       = false
  }
}

data "aws_availability_zones" "available" {
}

data "aws_caller_identity" "current" {
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster-name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster-name
}
