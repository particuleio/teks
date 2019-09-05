#
# Provider Configuration
#
provider "aws" {
  region = var.aws["region"]
}

terraform {
  backend "s3" {
  }
}

# Using these data sources allows the configuration to be
# generic for any region.
data "aws_region" "current" {
}

data "aws_availability_zones" "available" {
}

data "aws_caller_identity" "current" {
}

provider "helm" {
  install_tiller                  = true
  service_account                 = "tiller"
  tiller_image                    = "gcr.io/kubernetes-helm/tiller:v2.14.3"
  automount_service_account_token = true

  kubernetes {
    config_path = var.eks["kubeconfig_path"]
  }
}

provider "kubernetes" {
  config_path = var.eks["kubeconfig_path"]
}

provider "tls" {
}

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = var.eks["remote_state_bucket"]
    key    = var.eks["remote_state_key"]
    region = var.eks["remote_state_bucket_region"]
  }
}
