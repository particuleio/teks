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
