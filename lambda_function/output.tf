output "function_arn" {
  value = local.function_arn
}

output "function_name" {
  value = local.function_name
}

output "output_kinesis_stream_arn" {
  value = local.output_kinesis_stream_arn
}

output "output_kinesis_stream_name" {
  value = local.output_kinesis_stream_name
}

output "output_sns_stream_arn" {
  value = local.output_sns_stream_arn
}

output "output_sns_stream_name" {
  value = local.output_sns_stream_name
}

output "output_sqs_stream_arn" {
  value = local.output_sqs_stream_arn
}

output "output_sqs_stream_id" {
  value = local.output_sqs_stream_id
}

output "api_gateway_resource_id" {
  value = element(concat(aws_api_gateway_resource.api_resource.*.id, [""]), 0)
}

locals {
  function_arn = element(
    concat(
      aws_lambda_function.aws_lambda_function.*.arn,
      aws_lambda_function.aws_lambda_function_with_vpc.*.arn,
    ),
    0,
  )
  function_name = element(
    concat(
      aws_lambda_function.aws_lambda_function.*.function_name,
      aws_lambda_function.aws_lambda_function_with_vpc.*.function_name,
    ),
    0,
  )
}

locals {
  invoke_url = element(
    concat(aws_api_gateway_deployment.api_deployment.*.invoke_url, [""]),
    0,
  )
  path = element(
    concat(aws_api_gateway_resource.api_resource.*.path, [""]),
    0,
  )
}

output "invoke_url" {
  value = "${local.invoke_url}${local.path}"
}
