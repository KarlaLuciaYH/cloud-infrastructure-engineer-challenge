terraform {
  backend "s3" {
    bucket = "state-bucket-test-100"
    key    = "lambda-rds-apigw-infra/terraform2.tfstate"
    region = "us-east-1"
  }
}
