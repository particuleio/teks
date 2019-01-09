variable "aws" {
  type    = "map"
  default = {}
}

variable "eks" {
  type    = "map"
  default = {}
}

variable "nginx_ingress" {
  type    = "map"
  default = {}
}

variable "cluster_autoscaler" {
  type    = "map"
  default = {}
}

variable "external_dns" {
  type    = "map"
  default = {}
}

variable "cert_manager" {
  type    = "map"
  default = {}
}

variable "kiam" {
  type    = "map"
  default = {}
}

variable "metrics_server" {
  type    = "map"
  default = {}
}

variable "prometheus_operator" {
  type    = "map"
  default = {}
}

variable "virtual_kubelet" {
  type    = "map"
  default = {}
}
