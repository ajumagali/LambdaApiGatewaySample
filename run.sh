#!/usr/bin/env bash

# compress Lambda function
cd lambda
zip -r -X lambda.zip . -i index.js

# initialize terraform
cd ../provision/
terraform init
terraform apply