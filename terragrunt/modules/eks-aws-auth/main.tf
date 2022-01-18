terraform {
  required_providers {
    utils = {
      source  = "cloudposse/utils"
      version = "0.17.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.7.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

variable "aws_auth_computed" {}

variable "aws_auth" {}

variable "cluster-name" {}

data "utils_deep_merge_yaml" "aws_auth" {
  input = [
    var.aws_auth_computed,
    var.aws_auth
  ]
}

resource "kubectl_manifest" "aws-auth" {
  yaml_body = data.utils_deep_merge_yaml.aws_auth.output
}

output "aws_auth" {
  value = data.utils_deep_merge_yaml.aws_auth.output
}
