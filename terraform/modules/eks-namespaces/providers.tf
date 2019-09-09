#
# Provider Configuration
#
terraform {
  backend "s3" {
  }
}

provider "kubernetes" {
  config_path = var.eks["kubeconfig_path"]
}

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = var.eks["remote_state_bucket"]
    key    = var.eks["remote_state_key"]
    region = var.aws["region"]
  }
}

