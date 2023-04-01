# Task role assume policy
data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect  = var.effect
    actions = var.actions

    principals {
      type        = var.role_type
      identifiers = [var.identifier]
    }

    dynamic "condition" {
      for_each = var.conditions
      content {
        test     = condition.value["test"]
        values   = condition.value["values"]
        variable = condition.value["variable"]
      }
    }
  }
}

resource "aws_iam_role" "service_role" {
  name               = "${var.name}-role"
  path               = var.path
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
}

module "role_policies" {
  source = "../iam-service-role-policy"
  for_each = {
    for policy in var.policies : policy.policy_name => policy
    if policy != null
  }
  role_name          = aws_iam_role.service_role.name
  policy_name        = each.value.policy_name
  policy_type        = each.value.policy_type
  custom_permissions = lookup(each.value, "custom_permissions", null)
}
