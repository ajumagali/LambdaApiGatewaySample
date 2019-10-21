# LambdaApiGatewaySample
This project deploys a simple [AWS Lambda](https://aws.amazon.com/lambda/) function that receives a word in English and translates it to a selected language (i.e., Kazakh, Russian, and Turkish).

The architecture is straightforward and it consists of an HTML page with Javascript with the [Lambda Proxy Integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html) using [Amazon API Gateway](https://aws.amazon.com/api-gateway/).

The project includes `index.html` as a front end, and `index.js` an AWS Lambda backend. The AWS resources are provisioned using `Terraform v0.12.2`, and `run.sh` compresses the Lambda function so it can be uploaded to AWS.  