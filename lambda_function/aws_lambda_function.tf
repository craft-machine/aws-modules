locals {
  source_code_hash        = length(var.package) == 0 ? join("", data.archive_file.function_zip.*.output_base64sha256) : filebase64sha256(var.package)
  filename                = length(var.package) == 0 ? local.function_source_zip : var.package
  handler_name            = length(var.handler_name) == 0 ? "lambda_function.lambda_function" : var.handler_name
  kinesis_stream_name_env = map("kinesis_stream_name", local.output_kinesis_stream_name)
  sns_stream_name_env     = map("sns_stream_name", local.output_sns_stream_name)
  sqs_stream_id_env       = map("sqs_stream_id", local.output_sqs_stream_id)
}

resource "aws_lambda_function" "aws_lambda_function" {
  count = var.vpc_enabled ? 0 : 1

  filename         = local.filename
  source_code_hash = local.source_code_hash
  function_name    = format("%s_function", var.name)
  role             = aws_iam_role.iam_for_function.arn
  handler          = local.handler_name

  memory_size = var.memory_size

  reserved_concurrent_executions = var.concurrency

  tracing_config {
    mode = "PassThrough"
  }

  timeout = var.timeout
  runtime = var.runtime
  tags    = var.tags

  environment {
    variables = merge(
      var.environment,
      local.kinesis_stream_name_env,
      local.sns_stream_name_env,
      local.sqs_stream_id_env,
      map("kinesis_event_source_arn", var.kinesis_event_source_arn),
      map("sns_event_source_arn", var.sns_event_source_arn)
    )
  }

  layers = var.layers
}

resource "aws_lambda_function" "aws_lambda_function_with_vpc" {
  count = var.vpc_enabled ? 1 : 0

  filename         = local.filename
  source_code_hash = local.source_code_hash

  function_name = format("%s_function", var.name)

  memory_size = var.memory_size

  role    = aws_iam_role.iam_for_function.arn
  handler = local.handler_name

  reserved_concurrent_executions = var.concurrency

  tracing_config {
    mode = "PassThrough"
  }

  timeout = var.timeout
  runtime = var.runtime
  tags    = var.tags

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }

  environment {
    variables = merge(
      var.environment,
      local.kinesis_stream_name_env,
      local.sns_stream_name_env,
      local.sqs_stream_id_env,
      map("kinesis_event_source_arn", var.kinesis_event_source_arn),
      map("sns_event_source_arn", var.sns_event_source_arn)
    )
  }

  layers = var.layers
}
