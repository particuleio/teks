variable "cluster-name" {
  default = "sample-cluster"
  type    = string
}
variable "aws" {
  type    = map(string)
  default = {}
}

variable "eks" {
  type    = map(string)
  default = {}
}

variable "nginx_ingress" {
  type    = map(string)
  default = {}
}

variable "cluster_autoscaler" {
  type    = map(string)
  default = {}
}

variable "external_dns" {
  type    = map(string)
  default = {}
}

variable "cert_manager" {
  type    = map(string)
  default = {}
}

variable "kiam" {
  type    = map(string)
  default = {}
}

variable "metrics_server" {
  type    = map(string)
  default = {}
}

variable "prometheus_operator" {
  type    = map(string)
  default = {}
}

variable "virtual_kubelet" {
  type    = map(string)
  default = {}
}

variable "fluentd_cloudwatch" {
  type    = map(string)
  default = {}
}

variable "npd" {
  type    = map(string)
  default = {}
}

variable "flux" {
  type    = map(string)
  default = {}
}

variable "sealed_secrets" {
  type    = map(string)
  default = {}
}

variable "istio" {
  type    = map(string)
  default = {}
}

variable "cni_metrics_helper" {
  type    = map(string)
  default = {}
}
