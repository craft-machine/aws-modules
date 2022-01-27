locals {
  logs_error_metric_name      = "${local.function_name}_logs_errors_count"
  json_logs_error_metric_name = "${local.function_name}_json_logs_errors_count"
  metrics_namespace           = "data_pipelines"
  log_group_name              = "/aws/lambda/${local.function_name}"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = local.log_group_name
  tags              = var.tags
  retention_in_days = 90
}

resource "aws_cloudwatch_metric_alarm" "function_error_alarm" {
  count               = terraform.workspace == "production" ? 1 : 0
  alarm_name          = "${var.name}_function_error_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.function_errors_evaluation_periods
  datapoints_to_alarm = var.function_errors_datapoints
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = var.function_errors_alarm_period
  threshold           = var.function_errors_alarm_threshold
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${var.name}_function"
  }

  alarm_description = "This metric monitors ${var.name} on ${terraform.workspace}"
  alarm_actions     = [var.alarm_arn]
}

resource "aws_cloudwatch_metric_alarm" "function_iterator_age_alarm" {
  count               = terraform.workspace == "production" ? 1 : 0
  alarm_name          = "${var.name}_function_iterator_age_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "IteratorAge"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Maximum"
  threshold           = var.iterator_age_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${var.name}_function"
  }

  alarm_description = "This metric monitors ${var.name} on ${terraform.workspace}"
  alarm_actions     = [var.alarm_arn]
}

data "aws_iam_policy_document" "iam_base_policy_document_access_for_function" {
  statement {
    actions = [
      "logs:*",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "cloudwatch:*",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "base_policy_for_function" {
  name   = "base_policy_for_${var.name}_function"
  policy = data.aws_iam_policy_document.iam_base_policy_document_access_for_function.json
}

resource "aws_cloudwatch_log_metric_filter" "logs_errors_count" {
  name           = "logs_errors_count"
  pattern        = "\"[ERROR]\""
  log_group_name = aws_cloudwatch_log_group.lambda_log_group.name

  metric_transformation {
    name      = local.logs_error_metric_name
    namespace = local.metrics_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "json_logs_errors_count" {
  name           = "json_logs_errors_count"
  pattern        = "{$.event=\"error_occurred\"}"
  log_group_name = aws_cloudwatch_log_group.lambda_log_group.name

  metric_transformation {
    name      = local.json_logs_error_metric_name
    namespace = local.metrics_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "logs_errors_count_alarm" {
  count               = terraform.workspace == "production" ? 1 : 0
  alarm_name          = "${local.logs_error_metric_name}_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.logs_errors_evaluation_periods
  datapoints_to_alarm = var.logs_errors_datapoints
  metric_name         = local.logs_error_metric_name
  namespace           = local.metrics_namespace
  period              = var.logs_errors_alarm_period
  threshold           = var.logs_errors_alarm_threshold
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  alarm_description = "This metric monitors ${local.logs_error_metric_name} on ${terraform.workspace}"
  alarm_actions     = [var.alarm_arn]
}

resource "aws_cloudwatch_metric_alarm" "json_logs_errors_count_alarm" {
  count               = terraform.workspace == "production" ? 1 : 0
  alarm_name          = "${local.json_logs_error_metric_name}_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.logs_errors_evaluation_periods
  datapoints_to_alarm = var.logs_errors_datapoints
  metric_name         = local.json_logs_error_metric_name
  namespace           = local.metrics_namespace
  period              = var.logs_errors_alarm_period
  threshold           = var.logs_errors_alarm_threshold
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  alarm_description = "This metric monitors ${local.json_logs_error_metric_name} on ${terraform.workspace}"
  alarm_actions     = [var.alarm_arn]
}
