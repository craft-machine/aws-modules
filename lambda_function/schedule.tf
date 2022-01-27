resource "aws_cloudwatch_event_rule" "lambda_function_event_rule" {
  count               = var.schedule_expression_enabled ? 1 : 0
  name                = "${local.function_name}_event_rule"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda_function_cloudwatch_event_target" {
  count     = var.schedule_expression_enabled ? 1 : 0
  rule      = aws_cloudwatch_event_rule.lambda_function_event_rule[0].name
  arn       = local.function_arn
  target_id = "${local.function_name}_event_target"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count         = var.schedule_expression_enabled ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = local.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_function_event_rule[0].arn
}
