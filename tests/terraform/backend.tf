terraform {
  backend "s3" {
    bucket = "craft-tfstate"
    key    = "lambda_function_test.tfstate"
    region = "us-east-1"
  }
}

