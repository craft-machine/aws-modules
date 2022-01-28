terraform {
  backend "s3" {
    bucket = "craft-tfstate"
    key    = "lambda_function_test.tfstate"
    region = var.aws_region
  }
}

