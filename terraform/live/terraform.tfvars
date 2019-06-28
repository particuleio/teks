terragrunt = {
  remote_state {
    backend = "s3"
    config {
      bucket         = "sample-terraform-remote-state-0-11"
      key            = "${path_relative_to_include()}"
      region         = "eu-west-1"
      encrypt        = true
      dynamodb_table = "sample-terraform-remote-state-0-11"
    }
  }
}
