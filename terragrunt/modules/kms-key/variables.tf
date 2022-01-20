variable "description" {
  type    = string
  default = ""
}

variable "enable_key_rotation" {
  type    = bool
  default = true
}

variable "alias" {
  type = string
}

variable "tags" {
  type    = map(any)
  default = {}
}
