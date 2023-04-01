variable "role_name" {
  type = string
}

variable "policy_name" {
  type = string
}

variable "policy_type" {
  type = string
}

variable "custom_permissions" {
  type    = any
  default = null
}
