resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  count     = var.sns_event_source_enabled ? 1 : 0
  topic_arn = var.sns_event_source_arn
  protocol  = "lambda"
  endpoint  = local.function_arn
}

data "aws_iam_policy_document" "iam_policy_document_access_for_sns_event_source" {
  count = var.sns_event_source_enabled ? 1 : 0

  statement {
    actions = [
      "sns:*",
    ]

    resources = [
      var.sns_event_source_arn,
    ]
  }
}

resource "aws_iam_policy" "policy_for_function_sns_event_source" {
  count  = var.sns_event_source_enabled ? 1 : 0
  name   = "policy_for_${var.name}_function_sns_event_source"
  policy = data.aws_iam_policy_document.iam_policy_document_access_for_sns_event_source[0].json
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment_for_function_sns_event_source" {
  count      = var.sns_event_source_enabled ? 1 : 0
  role       = aws_iam_role.iam_for_function.name
  policy_arn = aws_iam_policy.policy_for_function_sns_event_source[0].arn
}

resource "aws_lambda_permission" "aws_lambda_sns_permission" {
  count         = var.sns_event_source_enabled ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = local.function_arn
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_event_source_arn
}
