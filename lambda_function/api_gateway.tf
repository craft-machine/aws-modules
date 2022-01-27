data "aws_caller_identity" "current" {
}

resource "aws_api_gateway_resource" "api_resource" {
  count       = length(var.path) == 0 ? 0 : 1
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = var.path
}

resource "aws_api_gateway_method" "api_method" {
  count            = length(var.path) == 0 ? 0 : 1
  rest_api_id      = var.rest_api_id
  resource_id      = aws_api_gateway_resource.api_resource[0].id
  http_method      = var.http_method
  authorization    = "NONE"
  api_key_required = var.api_key_required
}

resource "aws_api_gateway_method_settings" "api_method" {
  count       = length(var.path) == 0 ? 0 : 1
  rest_api_id = var.rest_api_id
  stage_name  = var.api_gateway_stage_name
  method_path = "${var.path}/${var.http_method}"

  settings {
    logging_level = "INFO"
  }

  depends_on = [aws_api_gateway_deployment.api_deployment]
}

resource "aws_api_gateway_method" "options_method" {
  count = var.cors_enabled ? 1 : 0

  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.api_resource[0].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_200" {
  count = var.cors_enabled ? 1 : 0

  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.api_resource[0].id
  http_method = aws_api_gateway_method.options_method[0].http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.options_method]
}

resource "aws_api_gateway_integration" "options_integration" {
  count = var.cors_enabled ? 1 : 0

  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.api_resource[0].id
  http_method = aws_api_gateway_method.options_method[0].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }

  depends_on = [aws_api_gateway_method.options_method]
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  count = var.cors_enabled ? 1 : 0

  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.api_resource[0].id
  http_method = aws_api_gateway_method.options_method[0].http_method
  status_code = aws_api_gateway_method_response.options_200[0].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,Access-Control-Allow-Origin'"
    "method.response.header.Access-Control-Allow-Methods" = "'${var.http_method},OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${var.allow_origin_url}'"
  }

  depends_on = [aws_api_gateway_method_response.options_200]
}

resource "aws_api_gateway_integration" "api_method_integration" {
  count       = length(var.path) == 0 ? 0 : 1
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.api_resource[0].id
  http_method = aws_api_gateway_method.api_method[0].http_method
  type        = "AWS_PROXY"

  uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${local.function_arn}/invocations"

  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  count = length(var.path) == 0 ? 0 : 1

  depends_on = [
    aws_api_gateway_method.api_method,
    aws_api_gateway_integration.api_method_integration,
  ]

  rest_api_id       = var.rest_api_id
  stage_name        = var.api_gateway_stage_name
  stage_description = "Deployment ${aws_api_gateway_method.api_method[0].id} ${aws_api_gateway_integration.api_method_integration[0].id} ${aws_lambda_permission.api_gateway_lambda_permission[0].id}"
}

resource "aws_lambda_permission" "api_gateway_lambda_permission" {
  count = length(var.path) == 0 ? 0 : 1

  depends_on = [aws_api_gateway_resource.api_resource]

  statement_id  = "AllowExecutionFromAPIGateway_${replace(var.path, "/", "_")}"
  action        = "lambda:InvokeFunction"
  function_name = local.function_arn
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.rest_api_id}/*/${var.http_method}${aws_api_gateway_resource.api_resource[0].path}"
}
