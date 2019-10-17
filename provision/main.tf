#configure the AWS provider
provider "aws" {
  region = "${var.region}"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "online_translate_lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "translator" {
  filename = "../lambda/lambda.zip"
  function_name = "online-translator"
  description = "AWS Lambda function to translate from English"
  handler = "index.handler"
  role = "${aws_iam_role.iam_for_lambda.arn}"
  runtime = "nodejs8.10"
  source_code_hash = "${filebase64sha256("../lambda/lambda.zip")}"
}

resource "aws_api_gateway_rest_api" "static-web-to-lambda-api" {
  name = "online-translator"
  description = "Terraform Serverless Application Example"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_method" "post-method" {
  authorization = "NONE"
  http_method = "POST"
  resource_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
}

resource "aws_api_gateway_method_response" "post-200" {
  http_method = "${aws_api_gateway_method.post-method.http_method}"
  resource_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  depends_on = ["aws_api_gateway_method.post-method"]
}

resource "aws_api_gateway_integration" "post-integration"{
  http_method = "${aws_api_gateway_method.post-method.http_method}"
  resource_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
  integration_http_method = "POST"
  type = "AWS"
  uri = "${aws_lambda_function.translator.invoke_arn}"
  depends_on = [
    "aws_api_gateway_method.post-method",
    "aws_lambda_function.translator"
  ]
}

resource "aws_api_gateway_integration_response" "post-integration-response" {
  http_method = "${aws_api_gateway_method.post-method.http_method}"
  resource_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
  status_code = "${aws_api_gateway_method_response.post-200.status_code}"
  depends_on = [
    "aws_api_gateway_method_response.post-200",
    "aws_api_gateway_integration.post-integration"
  ]
}

resource "aws_api_gateway_method" "get-method" {
  authorization = "NONE"
  http_method = "GET"
  resource_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
}

resource "aws_api_gateway_method_response" "get-200" {
  http_method = "${aws_api_gateway_method.get-method.http_method}"
  resource_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  depends_on = ["aws_api_gateway_method.get-method"]
}

resource "aws_api_gateway_integration" "get-integration"{
  http_method = "${aws_api_gateway_method.get-method.http_method}"
  resource_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
  integration_http_method = "POST"
  type = "AWS"
  uri = "${aws_lambda_function.translator.invoke_arn}"
  depends_on = [
    "aws_api_gateway_method.get-method",
    "aws_lambda_function.translator"
  ]
}

resource "aws_api_gateway_integration_response" "get-integration-response" {
  http_method = "${aws_api_gateway_method.get-method.http_method}"
  resource_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
  status_code = "${aws_api_gateway_method_response.post-200.status_code}"
  depends_on = [
    "aws_api_gateway_method_response.get-200",
    "aws_api_gateway_integration.get-integration"
  ]
}

module "apigateway-cors" {
  source  = "bridgecrewio/apigateway-cors/aws"
  version = "1.1.0"
  # insert the 3 required variables here
  api = aws_api_gateway_rest_api.static-web-to-lambda-api.id
  resources = [aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id]

  methods = ["GET", "POST", "OPTIONS"]
}

resource "aws_api_gateway_deployment" "translator-deployment" {
  depends_on = [
    "aws_api_gateway_integration_response.post-integration-response",
    "aws_api_gateway_integration_response.get-integration-response",
    "aws_api_gateway_integration.get-integration",
    "aws_api_gateway_integration.post-integration"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
  stage_name = "test"
}

resource "aws_lambda_permission" "lambda-permission" {
  statement_id  = "AllowExecutionFromAPIGatewayPost"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.translator.function_name}"
  principal     = "apigateway.amazonaws.com"
  //source_arn = "${aws_api_gateway_rest_api.static-web-to-lambda-api.execution_arn}/*/*/*"
  source_arn = "arn:aws:execute-api:${var.region}:${var.accountId}:${aws_api_gateway_rest_api.static-web-to-lambda-api.id}/*/*/"

  depends_on = ["aws_api_gateway_rest_api.static-web-to-lambda-api"]
}

resource "aws_s3_bucket" "static-web-bucket" {
  bucket = "${var.bucket-name}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.bucket-name}/*"
        }
    ]
}
POLICY

  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket_object" "static-web-content" {
  bucket = "${aws_s3_bucket.static-web-bucket.bucket}"
  key = "index.html"
  content = "${replace(file("../html/index.html"), "###api-gateway-endpoint###", aws_api_gateway_deployment.translator-deployment.invoke_url)}"
  content_type = "text/html"
}
