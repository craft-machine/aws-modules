resource "aws_s3_bucket_object" "query_api_monitoring" {
  bucket = var.bucket_name
  key    = "${var.api_name}${var.template_name_suffix}"
  source = var.source_file
  etag   = filemd5(var.source_file)
}

resource "aws_cloudwatch_metric_alarm" "query_api_monitoring_alarm" {
  alarm_name    = "monitoring_${var.api_name}_alarm"
  alarm_actions = [var.alarm_action_arn]
  ok_actions    = [var.alarm_action_arn]

  period              = var.alarm_period
  evaluation_periods  = var.alarm_evaluation_periods
  threshold           = var.alarm_threshold
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"

  statistic   = "SampleCount"
  metric_name = var.alarm_metric_name
  namespace   = var.alarm_metric_namespace

  dimensions = {
    "${var.alarm_metric_dimention}" = var.api_name
  }
}
