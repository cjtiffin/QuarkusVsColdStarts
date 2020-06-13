###########################################################
# Module inputs
###########################################################
variable "api_gateway_name" {}

variable "role" {}
variable "name" {}
variable "runtime" {}
variable "handler" {}
variable "folder" {}
variable "filename" {}

variable "environment" {
  default = {
    "ignore" = "ignore"
  }
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
    variables = "${var.environment}"
  }
}

module "api" {
  source = "../setup_api"

  api_gateway_name  = "${var.api_gateway_name}"
  path_part         = "${var.name}"
  lambda_arn        = "${aws_lambda_function.main.arn}"
  lambda_invoke_arn = "${aws_lambda_function.main.invoke_arn}"
}

###########################################################
# Lambda provisioned concurrency
###########################################################
resource "aws_lambda_alias" "pc" {
  name             = "pc"
  description      = "For provisioned capacity testing"
  function_name    = "${aws_lambda_function.main.arn}"
  function_version = "${aws_lambda_function.main.version}"
}

module "pc_api" {
  source = "../setup_api"

  api_gateway_name  = "${var.api_gateway_name}"
  path_part         = "pc-${var.name}"
  lambda_arn        = "${aws_lambda_alias.pc.arn}"
  lambda_invoke_arn = "${aws_lambda_alias.pc.invoke_arn}"
}

resource "aws_lambda_provisioned_concurrency_config" "pc" {
  function_name                     = "${aws_lambda_function.main.function_name}"
  qualifier                         = "${aws_lambda_alias.pc.name}"
  provisioned_concurrent_executions = 2
}
