###########################################################
# Module inputs
###########################################################
variable "api_gateway_name" {}

variable "path_part" {}
variable "lambda_arn" {}
variable "lambda_invoke_arn" {}

data "aws_api_gateway_rest_api" "main" {
  name = "${var.api_gateway_name}"
}

###########################################################
# Create the api resource, method and integration
###########################################################
resource "aws_api_gateway_resource" "main" {
  rest_api_id = "${data.aws_api_gateway_rest_api.main.id}"
  parent_id   = "${data.aws_api_gateway_rest_api.main.root_resource_id}"
  path_part   = "${var.path_part}"
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
  uri                     = "${var.lambda_invoke_arn}"
}

###########################################################
# Give the API permissions to invoke the lambda
###########################################################
resource "aws_lambda_permission" "main" {
  statement_id  = "AllowMyRequestAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${var.lambda_arn}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${data.aws_api_gateway_rest_api.main.execution_arn}/*/*/*"
}
