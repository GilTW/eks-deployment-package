variable "project" {
  type = string
}

variable "cluster_name" {
  type = string
  default = "eks-cluster"
}

variable "cluster_public_access_cidrs" {
  type    = list(string)
  default = []
}

variable "k8s_version" {
  type = string
}

variable "node_groups" {
  type = any
}

variable "public_subnet_ids" {
  type = list(string)
  default = []
}

variable "private_subnet_ids" {
  type = list(string)
  default = []
}

variable "public_subnet_ids_dep" {
  type = list(string)
}

variable "private_subnet_ids_dep" {
  type = list(string)
}
