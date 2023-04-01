variable "name" {
  type = string
}

variable "path" {
  type    = string
  default = null
}

variable "identifier" {}

variable "policies" {
  type    = any
  default = []
}

variable "conditions" {
  type    = any
  default = []
}

variable "role_type" {
  default = "Service"
}

variable "actions" {
  default = ["sts:AssumeRole"]
  type    = list(string)
}

variable "effect" {
  type    = string
  default = "Allow"
}
