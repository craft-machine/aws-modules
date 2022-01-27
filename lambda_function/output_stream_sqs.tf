resource "aws_sqs_queue" "output_sqs_stream" {
  count                       = var.output_sqs_stream_enabled ? 1 : 0
  name                        = "${var.name}_function_sqs_stream${var.sqs_fifo_queue ? ".fifo" : ""}"
  visibility_timeout_seconds  = max(var.timeout, var.sqs_visibility_timeout_seconds)
  message_retention_seconds   = var.sqs_message_retention_seconds
  fifo_queue                  = var.sqs_fifo_queue
  content_based_deduplication = var.sqs_content_based_deduplication
  tags                        = var.tags
}

data "aws_iam_policy_document" "iam_policy_document_access_for_function_output_sqs_stream" {
  count = var.output_sqs_stream_enabled ? 1 : 0

  statement {
    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.output_sqs_stream[0].arn]
  }
}

resource "aws_iam_policy" "policy_for_function_output_sqs_stream" {
  count  = var.output_sqs_stream_enabled ? 1 : 0
  name   = "policy_for_${var.name}_function_output_sqs_stream"
  policy = data.aws_iam_policy_document.iam_policy_document_access_for_function_output_sqs_stream[0].json
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment_for_function_output_sqs_stream" {
  count      = var.output_sqs_stream_enabled ? 1 : 0
  role       = aws_iam_role.iam_for_function.name
  policy_arn = aws_iam_policy.policy_for_function_output_sqs_stream[0].arn
}

locals {
  output_sqs_stream_arn = join("", aws_sqs_queue.output_sqs_stream.*.arn)
  output_sqs_stream_id  = join("", aws_sqs_queue.output_sqs_stream.*.id)
}
