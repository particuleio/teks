remote_state {
  backend = "s3"
  config = {
    bucket         = "teks-terraform-remote-state"
    key            = "${path_relative_to_include()}"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "teks-terraform-remote-state"
  }
}
