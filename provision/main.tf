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
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_method" "http-method-any" {
  authorization = "NONE"
  http_method = "ANY"
  resource_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
}

resource "aws_api_gateway_method_response" "response_200" {
  http_method = "${aws_api_gateway_method.http-method-any.http_method}"
  resource_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
  status_code = "200"
}


//resource "aws_api_gateway_method" "get-method" {
//  authorization = "NONE"
//  http_method = "GET"
//  resource_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id}"
//  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
//}

resource "aws_api_gateway_integration" "apigw-lambda-intg"{
  http_method = "${aws_api_gateway_method.http-method-any.http_method}"
  resource_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
  integration_http_method = "POST"
  type = "AWS"
  uri = "${aws_lambda_function.translator.invoke_arn}"
}

resource "aws_api_gateway_integration_response" "lambda-intg-resp" {
  http_method = "${aws_api_gateway_method.http-method-any.http_method}"
  resource_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
  status_code = "${aws_api_gateway_method_response.response_200.status_code}"
}

resource "aws_lambda_permission" "api-gw-lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.translator.function_name}"
  principal     = "apigateway.amazonaws.com"
  //source_arn = "arn:aws:execute-api:${var.region}:${var.accountId}:${aws_api_gateway_rest_api.static-web-to-lambda-api.id}/*/${aws_api_gateway_method.post-method.http_method}${aws_api_gateway_rest_api.static-web-to-lambda-api.root_resource_id}"
  source_arn = "${aws_api_gateway_rest_api.static-web-to-lambda-api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_deployment" "translator-deployment" {
  depends_on = ["aws_api_gateway_integration.apigw-lambda-intg"]
  rest_api_id = "${aws_api_gateway_rest_api.static-web-to-lambda-api.id}"
  stage_name = "test"
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
