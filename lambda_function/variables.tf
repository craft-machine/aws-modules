# LAMBDA #######################################################################
variable "aws_region" {
  default = "us-east-1"
}

variable "name" {
  description = "Name of your lambda function."
}

variable "handler_name" {
  description = "The function entrypoint in your code. Default lambda_function.lambda_function."
  default     = ""
}

variable "runtime" {
  description = "The runtime environment for the Lambda function you are uploading. Default python3.6."
  default     = "python3.9"
}

variable "package" {
  description = "The path to the function's deployment package within the local filesystem. If not defined, functions/$${var.name}/function/ folder will be used."
  default     = ""
}

variable "environment" {
  description = "The Lambda environment's configuration settings. Adds kinesis_stream_name, sns_stream_name."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A mapping of tags to assign to the object. Will be used for all resources that allow tags assignment."
  type        = map(string)
  default     = {}
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime. Defaults to 128."
  default     = 128
}

variable "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds. Defaults to 30."
  default     = 30
}

variable "vpc_subnet_ids" {
  description = "Will be used only if vpc_enabled = true."
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "Will be used only if vpc_enabled = true."
  type        = list(string)
  default     = []
}

variable "alarm_arn" {
  description = "The ARN of actions to execute when this alarm transitions into an OK/Alarm state from any other state."
}

variable "concurrency" {
  default = 1
}

variable "vpc_enabled" {
  default = false
}

variable "layers" {
  description = "List of lambda layer ARNs"
  type        = list(string)
  default     = []
}

# CLOUDWATCH ###################################################################

variable "schedule_expression_enabled" {
  default = false
}

variable "schedule_expression" {
  description = "The scheduling expression. For example, cron(0 20 * * ? *) or rate(5 minutes). Default is none. Will be used only if schedule_expression_enabled = true."
  default     = ""
}

variable "iterator_age_alarm_threshold" {
  default = "1200000"
}

variable "function_errors_alarm_period" {
  default = "60"
}

variable "function_errors_alarm_threshold" {
  default = "1"
}

variable "function_errors_evaluation_periods" {
  default = "2"
}

variable "function_errors_datapoints" {
  default = "2"
}

variable "logs_errors_alarm_period" {
  default = "60"
}

variable "logs_errors_alarm_threshold" {
  default = "1"
}

variable "logs_errors_evaluation_periods" {
  default = "2"
}

variable "logs_errors_datapoints" {
  default = "2"
}

# IAM ##########################################################################

variable "policy_json" {
  default = ""
}

variable "policy_json_enabled" {
  default = false
}

# KINESIS ######################################################################

variable "kinesis_retention_period" {
  description = "The amount of time Kinesis stream stores unprocessed events. Defaults to 24 hours."
  default     = 24
}

variable "kinesis_shard_count" {
  description = "The amount of time Kinesis stream shards. Defaults to 1."
  default     = 1
}

variable "kinesis_event_source_arn" {
  description = "The event source ARN - Kinesis stream. Will be used only if kinesis_event_source_enabled = true."
  default     = ""
}

variable "batch_size" {
  description = "The largest number of records that Lambda will retrieve from your event source at the time of invocation. Defaults to 10."
  default     = 10
}

variable "kinesis_event_source_enabled" {
  default = false
}

variable "output_kinesis_stream_enabled" {
  default = false
}

# SNS ##########################################################################

variable "sns_event_source_arn" {
  description = "The event source ARN - SNS topic. Will be used only if sns_event_source_enabled = true."
  default     = ""
}

variable "sns_event_source_enabled" {
  default = false
}

variable "output_sns_stream_enabled" {
  default = false
}

# SQS ##########################################################################

variable "sqs_event_source_enabled" {
  default = false
}

variable "sqs_event_source_arn" {
  description = "The event source ARN - SQS queue. Will be used only if sqs_event_source_enabled = true."
  default     = ""
}

variable "sqs_visibility_timeout_seconds" {
  default = 30
}

variable "sqs_message_retention_seconds" {
  default = 345600
}

variable "sqs_fifo_queue" {
  default = false
}

variable "sqs_content_based_deduplication" {
  default = false
}

variable "output_sqs_stream_enabled" {
  default = false
}

# API GATEWAY ##################################################################

variable "rest_api_id" {
  description = "The ID of the associated REST API."
  default     = ""
}

variable "parent_id" {
  description = "The ID of the parent API resource."
  default     = ""
}

variable "api_gateway_stage_name" {
  description = "Stage name in API Gateway for endpoints."
  default     = "api"
}

variable "path" {
  description = "The last path segment of this API resource."
  default     = ""
}

variable "http_method" {
  description = "The HTTP method (GET, POST, PUT, DELETE, HEAD, OPTION, ANY) when calling the associated lambda. Is used only if path specified."
  default     = ""
}

variable "api_key_required" {
  description = "Is api_key required for this endpoint."
  default     = true
}

variable "cors_enabled" {
  description = "Is cors enabled for this endpoint."
  default     = false
}

variable "allow_origin_url" {
  description = "Determines which resource can be accessed by content operating within the current origin"
  default     = ""
}
