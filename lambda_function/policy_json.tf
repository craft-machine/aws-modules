resource "aws_iam_policy" "policy_for_function" {
  count  = var.policy_json_enabled ? 1 : 0
  name   = "policy_for_${var.name}_function"
  policy = var.policy_json
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment_for_function" {
  count      = var.policy_json_enabled ? 1 : 0
  role       = aws_iam_role.iam_for_function.name
  policy_arn = aws_iam_policy.policy_for_function[0].arn
}
