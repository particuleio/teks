variable "aws" {
  type    = map(string)
  default = {}
}

variable "eks" {
  type    = map(string)
  default = {}
}

variable "flux" {
  type    = map(string)
  default = {}
}

variable "namespaces" {
  type    = any
  default = []
}

variable "env" {
}

