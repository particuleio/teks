variable "cluster-name" {
  default = "sample-cluster"
  type    = string
}

variable "aws" {
  type    = map(string)
  default = {}
}

variable "node-pools" {
  type    = any
  default = []
}

variable "dns" {
  type    = any
  default = {}
}

variable "kubernetes_version" {
  description = "EKS version"
  default     = "1.13"
}

variable "vpc" {
  type    = map(string)
  default = {}
}

variable "endpoint_public_access" {
  default = true
}

variable "endpoint_private_access" {
  default = false
}

variable "enabled_cluster_log_types" {
  type    = list(string)
  default = []
}

variable "cluster_log_retention_in_days" {
  default = 30
}

variable "allowed_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "ssh_remote_security_group_id" {
  default = ""
}

variable "map_users" {
  type = string
}

variable "map_roles" {
  type = string
}

variable "extra_network_policies" {
  default = ""
}

variable "kubeconfig_assume_role_arn" {
  default = ""
}

variable "custom_tags" {
  type    = map
  default = {}
}

variable "custom_tags_list" {
  type    = list
  default = []
}

variable "bastion" {
  type    = any
  default = {}
}
