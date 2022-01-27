provider "aws" {
  version    = "~> 3.55"
  region     = data.terraform_remote_state.network.outputs.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket     = "craft-tfstate"
    key        = "env:/${terraform.workspace}/network.tfstate"
    region     = "us-east-1"
    access_key = var.ops_access_key
    secret_key = var.ops_secret_key
  }
}

data "terraform_remote_state" "data_api_monitoring" {
  backend = "s3"

  config = {
    bucket     = "craft-tfstate"
    key        = "env:/${terraform.workspace}/data-api-monitoring.tfstate"
    region     = "us-east-1"
    access_key = var.ops_access_key
    secret_key = var.ops_secret_key
  }
}

module "test_step_0" {
  source = "../../lambda_function"

  name                = "test_step_0"
  timeout             = 2
  policy_json_enabled = false

  batch_size = 1

  output_kinesis_stream_enabled = false
  output_sns_stream_enabled     = true

  kinesis_event_source_enabled = false
  sns_event_source_enabled     = false

  vpc_enabled                 = false
  schedule_expression_enabled = false
  alarm_arn                   = data.terraform_remote_state.network.outputs.sns_data_pipelines_topic_arn
  concurrency                 = 2

  environment = {}
}

module "test_step_1" {
  source = "../../lambda_function"

  name                = "test_step_1"
  timeout             = 2
  policy_json_enabled = false

  batch_size = 1

  output_kinesis_stream_enabled = false
  output_sns_stream_enabled     = false

  kinesis_event_source_enabled = false

  sns_event_source_enabled = true

  sns_event_source_arn = module.test_step_0.output_sns_stream_arn

  vpc_enabled                 = false
  schedule_expression_enabled = false
  alarm_arn                   = data.terraform_remote_state.network.outputs.sns_data_pipelines_topic_arn
  environment                 = {}
}

module "test_step_sqs_event_source_in" {
  source = "../../lambda_function"

  name    = "test_step_sqs_event_source_in"
  timeout = 2

  batch_size = 1

  output_sqs_stream_enabled = true

  alarm_arn   = data.terraform_remote_state.network.outputs.sns_data_pipelines_topic_arn
  environment = {}
}

module "test_step_sqs_event_source_out" {
  source = "../../lambda_function"

  name    = "test_step_sqs_event_source_out"
  timeout = 2

  batch_size = 1

  sqs_event_source_enabled = true
  sqs_event_source_arn     = module.test_step_sqs_event_source_in.output_sqs_stream_arn

  alarm_arn   = data.terraform_remote_state.network.outputs.sns_data_pipelines_topic_arn
  environment = {}
}

module "test_step_api_monitoring" {
  source = "../../api_monitoring"

  api_name    = "test_api_monitoring"
  source_file = "../monitoring/test_api_monitoring_template"
  bucket_name = data.terraform_remote_state.data_api_monitoring.outputs.bucket_name

  template_name_suffix = data.terraform_remote_state.data_api_monitoring.outputs.template_name_suffix

  alarm_action_arn       = data.terraform_remote_state.network.outputs.sns_query_api_topic_arn
  alarm_period           = data.terraform_remote_state.data_api_monitoring.outputs.monitoring_period
  alarm_metric_name      = data.terraform_remote_state.data_api_monitoring.outputs.main_metric_name
  alarm_metric_dimention = data.terraform_remote_state.data_api_monitoring.outputs.metrics_dimention
  alarm_metric_namespace = data.terraform_remote_state.data_api_monitoring.outputs.metrics_namespace
}
