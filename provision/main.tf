#configure the AWS provider
provider "aws" {
  region = "eu-west-2"
}

resource "aws_s3_bucket" "static-web-bucket" {
  bucket = "${var.bucket-name}"
  acl = "public-read"
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