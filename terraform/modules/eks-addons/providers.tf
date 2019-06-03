#
# Provider Configuration
#
terraform {
  backend "s3" {}
}

provider "helm" {
  install_tiller                  = true
  service_account                 = "tiller"
  tiller_image                    = "gcr.io/kubernetes-helm/tiller:v2.14.0"
  automount_service_account_token = true

  kubernetes {
    config_path = "${var.eks["kubeconfig_path"]}"
  }
}

provider "kubernetes" {
  config_path = "${var.eks["kubeconfig_path"]}"
}

provider "tls" {}

data "terraform_remote_state" "eks" {
  backend = "s3"

  config {
    bucket = "${var.eks["remote_state_bucket"]}"
    key    = "${var.eks["remote_state_key"]}"
    region = "${var.aws["region"]}"
  }
}
