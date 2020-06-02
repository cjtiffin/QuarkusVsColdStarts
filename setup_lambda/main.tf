###########################################################
# Module inputs
###########################################################
variable "pc_test" {
  default = false
}

variable "api_gateway_name" {}
variable "role" {}

variable "name" {}
variable "runtime" {}
variable "handler" {}
variable "folder" {}
variable "filename" {}

variable "environment" {
  default = {}
}

data "aws_api_gateway_rest_api" "main" {
  name = "${var.api_gateway_name}"
}

###########################################################
# Lambda
###########################################################
resource "aws_lambda_function" "main" {
  role          = "${var.role}"
  function_name = "${var.name}Test"
  runtime       = "${var.runtime}"
  handler       = "${var.handler}"
  filename      = "${var.folder}/${var.filename}"
  publish       = true

  environment {
    variables = "${merge(
      var.environment,
      map("dummy", "empty")
    )}"
  }
}

resource "aws_lambda_permission" "main" {
  statement_id  = "AllowMyRequestAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.main.arn}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${data.aws_api_gateway_rest_api.main.execution_arn}/*/*/*"
}

###########################################################
# API Gateway for $LATEST ("unprovisioned")
###########################################################
resource "aws_api_gateway_resource" "main" {
  rest_api_id = "${data.aws_api_gateway_rest_api.main.id}"
  parent_id   = "${data.aws_api_gateway_rest_api.main.root_resource_id}"
  path_part   = "${var.name}"
}

resource "aws_api_gateway_method" "main" {
  rest_api_id   = "${data.aws_api_gateway_rest_api.main.id}"
  resource_id   = "${aws_api_gateway_resource.main.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "main" {
  rest_api_id             = "${data.aws_api_gateway_rest_api.main.id}"
  resource_id             = "${aws_api_gateway_resource.main.id}"
  http_method             = "${aws_api_gateway_method.main.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.main.invoke_arn}"
}

###########################################################
# Lambda provisioned concurrency (alias, api & config)
###########################################################
resource "aws_lambda_alias" "pc" {
  count = "${var.pc_test}"

  name             = "pc"
  description      = "For provisioned capacity testing"
  function_name    = "${aws_lambda_function.main.arn}"
  function_version = "${aws_lambda_function.main.version}"
}

resource "aws_api_gateway_resource" "pc" {
  count = "${var.pc_test}"

  rest_api_id = "${data.aws_api_gateway_rest_api.main.id}"
  parent_id   = "${data.aws_api_gateway_rest_api.main.root_resource_id}"
  path_part   = "pc_${var.name}"
}

resource "aws_api_gateway_method" "pc" {
  count = "${var.pc_test}"

  rest_api_id   = "${data.aws_api_gateway_rest_api.main.id}"
  resource_id   = "${aws_api_gateway_resource.pc.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "pc" {
  count = "${var.pc_test}"

  rest_api_id             = "${data.aws_api_gateway_rest_api.main.id}"
  resource_id             = "${aws_api_gateway_resource.pc.id}"
  http_method             = "${aws_api_gateway_method.pc.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_alias.pc.invoke_arn}"
}

resource "aws_lambda_provisioned_concurrency_config" "pc" {
  count = "${var.pc_test}"

  function_name                     = "${aws_lambda_alias.pc.function_name}"
  qualifier                         = "${aws_lambda_alias.pc.name}"
  provisioned_concurrent_executions = 2
}
