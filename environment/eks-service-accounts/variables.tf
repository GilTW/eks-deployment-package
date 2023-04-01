variable "project" {
  type = string
}

variable "eks_service_accounts" {
  type = any
}

variable "eks_oidc_issuer_dep" {
  type = string
}

variable "cluster_name_dep" {
  type = string
}