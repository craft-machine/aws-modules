resource "aws_lambda_event_source_mapping" "kinesis_event_source_mapping" {
  count             = var.kinesis_event_source_enabled ? 1 : 0
  batch_size        = var.batch_size
  event_source_arn  = var.kinesis_event_source_arn
  enabled           = true
  function_name     = local.function_arn
  starting_position = "TRIM_HORIZON"
}

data "aws_iam_policy_document" "iam_policy_document_access_for_kinesis_event_source" {
  count = var.kinesis_event_source_enabled ? 1 : 0

  statement {
    actions = [
      "kinesis:*",
    ]

    resources = [
      var.kinesis_event_source_arn,
    ]
  }
}

resource "aws_iam_policy" "policy_for_function_kinesis_event_source" {
  count  = var.kinesis_event_source_enabled ? 1 : 0
  name   = "policy_for_${var.name}_function_kinesis_event_source"
  policy = data.aws_iam_policy_document.iam_policy_document_access_for_kinesis_event_source[0].json
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment_for_function_kinesis_event_source" {
  count      = var.kinesis_event_source_enabled ? 1 : 0
  role       = aws_iam_role.iam_for_function.name
  policy_arn = aws_iam_policy.policy_for_function_kinesis_event_source[0].arn
}
