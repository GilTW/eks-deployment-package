output "annotations" {
  value = {
    for sa_name, sa_conf in var.eks_service_accounts : sa_name => {
      "eks.amazonaws.com/role-arn" = module.pod_sa_role[sa_name].arn
    }
  }
}
