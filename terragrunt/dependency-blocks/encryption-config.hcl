skip = true

dependency "encryption_config" {
  config_path = "${get_original_terragrunt_dir()}/../encryption-config"

  mock_outputs = {
    arn = "arn:::aws"
  }
}
