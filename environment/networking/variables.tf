variable "project" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "number_of_azs" {
  default = 2
  type    = number
}
