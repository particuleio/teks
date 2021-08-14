variable "description" {
  type    = string
  default = ""
}

variable "alias" {
  type = string
}

variable "tags" {
  type    = map(any)
  default = {}
}
