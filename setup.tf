###########################################################
# IAM setup
###########################################################
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

###########################################################
# Gateway setup
###########################################################
resource "aws_api_gateway_rest_api" "main" {
  name        = "quarkusVsJava-api"
  description = "To look at lambda cold starts"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

output "api_gateway_id" {
  value = "${aws_api_gateway_rest_api.main.id}"
}

###########################################################
# Go Lambda setup
###########################################################
module "go" {
  source = "setup_lambda"

  api_gateway_name = "${aws_api_gateway_rest_api.main.name}"
  role             = "${aws_iam_role.iam_for_lambda.arn}"

  name     = "go"
  runtime  = "go1.x"
  handler  = "testLambda"
  folder   = "Golang"
  filename = "testLambda.zip"
}

###########################################################
# Java Lambda setup
###########################################################
module "java" {
  source = "setup_lambda"

  api_gateway_name = "${aws_api_gateway_rest_api.main.name}"
  role             = "${aws_iam_role.iam_for_lambda.arn}"

  name     = "java"
  runtime  = "java8"
  handler  = "poc.TestLambda::handleRequest"
  folder   = "Java"
  filename = "target/lambda-java-1.0-SNAPSHOT.jar"
}

###########################################################
# Java 11 Lambda setup
###########################################################
module "java11" {
  source = "setup_lambda"

  api_gateway_name = "${aws_api_gateway_rest_api.main.name}"
  role             = "${aws_iam_role.iam_for_lambda.arn}"

  name     = "java11"
  runtime  = "java11"
  handler  = "poc.TestLambda::handleRequest"
  folder   = "Java11"
  filename = "target/lambda-java11-1.0-SNAPSHOT.jar"
}

###########################################################
# Node Lambda setup
###########################################################
module "node" {
  source = "setup_lambda"

  api_gateway_name = "${aws_api_gateway_rest_api.main.name}"
  role             = "${aws_iam_role.iam_for_lambda.arn}"

  name     = "node"
  runtime  = "nodejs12.x"
  handler  = "index.handler"
  folder   = "Node"
  filename = "testLambda.zip"
}

###########################################################
# Python Lambda setup
###########################################################
module "python" {
  source = "setup_lambda"

  api_gateway_name = "${aws_api_gateway_rest_api.main.name}"
  role             = "${aws_iam_role.iam_for_lambda.arn}"

  name     = "python"
  runtime  = "python3.8"
  handler  = "testLambda.lambda_handler"
  folder   = "Python"
  filename = "testLambda.zip"
}

###########################################################
# Quarkus Lambda setup
###########################################################
module "quarkus" {
  source = "setup_lambda"

  api_gateway_name = "${aws_api_gateway_rest_api.main.name}"
  role             = "${aws_iam_role.iam_for_lambda.arn}"

  name     = "quarkus"
  runtime  = "java8"
  handler  = "poc.TestLambda::handleRequest"
  folder   = "Quarkus"
  filename = "target/quarkusLambda-1.0-SNAPSHOT-runner.jar"
}

###########################################################
# Quarkus w/ GraalVM Lambda setup
###########################################################
# module "quarkusGraal" {
#   source = "setup_lambda"


#   api_gateway_name = "${aws_api_gateway_rest_api.main.name}"
#   role             = "${aws_iam_role.iam_for_lambda.arn}"


#   name     = "quarkusGraal"
#   runtime  = "provided"
#   handler  = "any.name.not.used"
#   folder   = "QuarkusGraal"
#   filename = "target/function.zip"


#   environment = {
#     DISABLE_SIGNAL_HANDLERS = "true"
#   }
# }

