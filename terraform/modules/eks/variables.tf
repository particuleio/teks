#
# Variables Configuration
#

variable "cluster-name" {
  default = "sample-cluster"
  type    = "string"
}

variable "aws" {
  type    = "map"
  default = {}
}

variable "node-pools" {
  default = []
  type    = "list"
}

variable "node-pools-tags" {
  default = []
  type    = "list"
}

variable "domain_name" {
  description = "Domain name of the parent domain where subdomain is created"
  default     = "domain.tld"
}

variable "subdomain_name" {
  description = "Subdomain name used to create an independant DNS zone"
  default     = "subdomain"
}

variable "subdomain_default_ttl" {
  description = "Subdomain zone default TTL"
  default     = "300"
}

variable "use_route53" {
  description = "Create route53 records"
  default     = false
}

variable "kubernetes_version" {
  description = "EKS version"
  default     = "1.12"
}

variable "external_dns" {
  type    = "map"
  default = {}
}

variable "cluster_autoscaler" {
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

variable "vpc" {
  type    = "map"
  default = {}
}

variable "nginx_ingress" {
  type    = "map"
  default = {}
}

variable "virtual_kubelet" {
  type    = "map"
  default = {}
}

variable "fluentd_cloudwatch" {
  type    = "map"
  default = {}
}

variable "cni_metrics_helper" {
  type    = "map"
  default = {}
}

variable "endpoint_public_access" {
  default = true
}

variable "endpoint_private_access" {
  default = false
}

variable "enabled_cluster_log_types" {
  type    = "list"
  default = []
}

variable "cluster_log_retention_in_days" {
  default = 30
}

variable "allowed_cidr_blocks" {
  type    = "list"
  default = ["0.0.0.0/0"]
}

variable "ssh_remote_security_group_id" {
  default = ""
}

variable "map_users" {
  type = "string"
}

variable "extra_network_policies" {
  default = ""
}
