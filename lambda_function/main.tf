resource "aws_iam_role" "iam_for_function" {
  name               = "iam_for_${var.name}_function"
  assume_role_policy = data.aws_iam_policy_document.iam_policy_document_for_assume_role.json
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_base_policy_attachment_for_function" {
  role       = aws_iam_role.iam_for_function.name
  policy_arn = aws_iam_policy.base_policy_for_function.arn
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment_for_function_with_vpc" {
  count      = var.vpc_enabled ? 1 : 0
  role       = aws_iam_role.iam_for_function.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "iam_policy_document_for_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
