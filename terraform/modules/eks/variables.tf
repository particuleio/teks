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
  default     = "1.11"
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

variable "nginx_ingress" {
  type    = "map"
  default = {}
}
