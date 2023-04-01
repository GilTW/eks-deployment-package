locals {
  full_cluster_name  = "${var.project}-${var.cluster_name}"
  public_subnet_ids  = length(var.public_subnet_ids) > 1 ? var.public_subnet_ids : var.public_subnet_ids_dep
  private_subnet_ids = length(var.private_subnet_ids) > 1 ? var.public_subnet_ids : var.public_subnet_ids_dep
}

data "http" "ip" {
  url = "https://ifconfig.me/ip"
}

resource "aws_eks_cluster" "main" {
  name     = local.full_cluster_name
  role_arn = module.eks_role.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids              = concat(local.public_subnet_ids, local.private_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = concat(["${data.http.ip.response_body}/32"], var.cluster_public_access_cidrs)
  }

  tags = {
    Name = local.full_cluster_name
  }

  depends_on = [
    module.eks_role
  ]
}

module "eks_role" {
  source     = "../../shared-modules/iam-service-role"
  identifier = "eks.amazonaws.com"
  name       = local.full_cluster_name

  policies = [
    {
      policy_name = "AmazonEKSClusterPolicy"
      policy_type = "MANAGED"
    },
  ]
}
