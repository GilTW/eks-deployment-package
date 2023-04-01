locals {
  policy_attachment_arn = var.policy_type == "MANAGED" ? data.aws_iam_policy.managed_permissions[0].arn : var.policy_type == "CUSTOM" ? aws_iam_policy.policy[0].arn : null
}

# Managed Permissions
data "aws_iam_policy" "managed_permissions" {
  count = var.policy_type == "MANAGED" ? 1 : 0
  name  = var.policy_name
}

# Custom Permissions
data "aws_iam_policy_document" "custom_permissions" {
  count = var.policy_type != "MANAGED" ? 1 : 0
  dynamic "statement" {
    for_each = var.custom_permissions != null ? [var.custom_permissions] : []

    content {
      actions   = statement.value.actions
      resources = statement.value.resources
      effect    = statement.value.effect

      dynamic "condition" {
        for_each = lookup(statement.value, "conditions", [])
        content {
          test     = condition.value["test"]
          variable = condition.value["variable"]
          values   = condition.value["values"]
        }
      }
    }
  }
}

# Inline Policy
resource "aws_iam_role_policy" "inline_policy" {
  count  = var.policy_type == "CUSTOM_INLINE" ? 1 : 0
  name   = var.policy_name
  role   = var.role_name
  policy = data.aws_iam_policy_document.custom_permissions[0].json
}


# Policy Object
resource "aws_iam_policy" "policy" {
  count  = var.policy_type == "CUSTOM" ? 1 : 0
  name   = var.policy_name
  policy = data.aws_iam_policy_document.custom_permissions[0].json
}

# Attachment - only if not inline
resource "aws_iam_role_policy_attachment" "role_attach" {
  count      = var.policy_type != "CUSTOM_INLINE" ? 1 : 0
  role       = var.role_name
  policy_arn = local.policy_attachment_arn
}
