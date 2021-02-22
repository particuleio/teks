terraform {
  required_version = ">= 0.12.2"

  backend "s3" {
    region         = "eu-west-1"
    bucket         = "pio-teks-tf-state-lock"
    key            = "terraform.tfstate"
    dynamodb_table = "pio-teks-tf-state-store-lock"
    profile        = ""
    role_arn       = ""
    encrypt        = "true"
  }
}
