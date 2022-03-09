terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.0"
    }
  }
}

variable "aws_auth_extra_roles" {}

variable "aws_auth_extra_users" {}

variable "aws_auth_computed" {}

variable "cluster-name" {}

locals {
  aws_auth_configmap_yaml = <<-CONTENT
    ${var.aws_auth_computed}
        ${indent(4, var.aws_auth_extra_roles)}
      ${indent(2, var.aws_auth_extra_users)}
    CONTENT
}

resource "kubectl_manifest" "this" {
  yaml_body = local.aws_auth_configmap_yaml
}

output "aws_auth_configmap_yaml" {
  value = local.aws_auth_configmap_yaml
}
