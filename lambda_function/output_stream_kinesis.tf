resource "aws_kinesis_stream" "output_kinesis_stream" {
  count            = var.output_kinesis_stream_enabled ? 1 : 0
  name             = "${var.name}_function_kinesis_stream"
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_period

  shard_level_metrics = [
    "IncomingRecords",
    "IteratorAgeMilliseconds",
    "OutgoingRecords",
  ]

  tags = var.tags
}

data "aws_iam_policy_document" "iam_policy_document_access_for_function_output_kinesis_stream" {
  count = var.output_kinesis_stream_enabled ? 1 : 0

  statement {
    actions = [
      "kinesis:*",
    ]

    resources = [
      aws_kinesis_stream.output_kinesis_stream[0].arn,
    ]
  }
}

resource "aws_iam_policy" "policy_for_function_output_kinesis_stream" {
  count  = var.output_kinesis_stream_enabled ? 1 : 0
  name   = "policy_for_${var.name}_function_output_kinesis_stream"
  policy = data.aws_iam_policy_document.iam_policy_document_access_for_function_output_kinesis_stream[0].json
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment_for_function_output_kinesis_stream" {
  count      = var.output_kinesis_stream_enabled ? 1 : 0
  role       = aws_iam_role.iam_for_function.name
  policy_arn = aws_iam_policy.policy_for_function_output_kinesis_stream[0].arn
}

locals {
  output_kinesis_stream_arn = element(
    concat(aws_kinesis_stream.output_kinesis_stream.*.arn, [""]),
    0,
  )
  output_kinesis_stream_name = element(
    concat(aws_kinesis_stream.output_kinesis_stream.*.name, [""]),
    0,
  )
}
