variable "eks" {
  type    = map(string)
  default = {}
}

variable "aws" {
  type    = any
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
