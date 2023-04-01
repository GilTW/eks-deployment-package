locals {
  oidc_issuer_no_schema = replace(var.eks_oidc_issuer_dep, "https://", "")
}

data "aws_caller_identity" "current" {}

# Service Role
module "pod_sa_role" {
  source   = "../../shared-modules/iam-service-role"
  for_each = var.eks_service_accounts

  role_type  = "Federated"
  identifier = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_issuer_no_schema}"
  name       = "${var.project}-${each.key}"
  actions    = ["sts:AssumeRoleWithWebIdentity"]

  conditions = [
    {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_no_schema}:aud"
      values   = ["sts.amazonaws.com"]
    },
    {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_no_schema}:sub"
      values   = ["system:serviceaccount:${each.value.k8s_namespace}:${each.key}"]
    }
  ]

  policies = each.value.iam_policies
}

resource "kubernetes_service_account_v1" "pod_sa" {
  for_each = var.eks_service_accounts

  metadata {
    name      = each.key
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.pod_sa_role[each.key].arn
    }
  }


  depends_on = [
    module.pod_sa_role
  ]
}
