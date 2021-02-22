terraform {
  required_version = ">= 0.13"
  required_providers {
    aws        = "~> 3.0"
    helm       = "~> 2.0"
    kubernetes = "~> 2.0"
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.0"
    }
  }
}
