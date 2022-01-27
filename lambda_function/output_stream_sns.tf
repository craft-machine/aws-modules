resource "aws_sns_topic" "output_sns_stream" {
  count = var.output_sns_stream_enabled ? 1 : 0
  name  = "${var.name}_function_sns_stream"
}

data "aws_iam_policy_document" "iam_policy_document_access_for_function_output_sns_stream" {
  count = var.output_sns_stream_enabled ? 1 : 0

  statement {
    actions = [
      "sns:*",
    ]

    resources = [
      aws_sns_topic.output_sns_stream[0].arn,
    ]
  }
}

resource "aws_iam_policy" "policy_for_function_output_sns_stream" {
  count  = var.output_sns_stream_enabled ? 1 : 0
  name   = "policy_for_${var.name}_function_output_sns_stream"
  policy = data.aws_iam_policy_document.iam_policy_document_access_for_function_output_sns_stream[0].json
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment_for_function_output_sns_stream" {
  count      = var.output_sns_stream_enabled ? 1 : 0
  role       = aws_iam_role.iam_for_function.name
  policy_arn = aws_iam_policy.policy_for_function_output_sns_stream[0].arn
}

data "aws_iam_policy_document" "iam_policy_document_create_topic_for_function_output_sns_stream" {
  count = var.output_sns_stream_enabled ? 1 : 0

  statement {
    actions = [
      "sns:CreateTopic",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "policy_for_function_create_topic_for_output_sns_stream" {
  count  = var.output_sns_stream_enabled ? 1 : 0
  name   = "policy_for_${var.name}_function_create_topic_for_output_sns_stream"
  policy = data.aws_iam_policy_document.iam_policy_document_create_topic_for_function_output_sns_stream[0].json
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment_create_topic_for_function_output_sns_stream" {
  count      = var.output_sns_stream_enabled ? 1 : 0
  role       = aws_iam_role.iam_for_function.name
  policy_arn = aws_iam_policy.policy_for_function_create_topic_for_output_sns_stream[0].arn
}

locals {
  output_sns_stream_arn  = element(concat(aws_sns_topic.output_sns_stream.*.arn, [""]), 0)
  output_sns_stream_name = element(concat(aws_sns_topic.output_sns_stream.*.name, [""]), 0)
}
