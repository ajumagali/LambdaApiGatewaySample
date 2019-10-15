#configure the AWS provider
provider "aws" {
  region = "eu-west-2"
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
  source = "../html/index.html"
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
  filename = "../lambda.zip"
  function_name = "index"
  description = "AWS Lambda function to translate from English"
  handler = "index.handler"
  role = "${aws_iam_role.iam_for_lambda.arn}"
  runtime = "nodejs8.10"
  source_code_hash = "${filebase64sha256("../lambda.zip")}"
}