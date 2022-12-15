skip = true

dependency "ebs_encryption" {
  config_path = "${get_original_terragrunt_dir()}/../ebs-encryption"

  mock_outputs = {
    key_arn = "arn:aws:iam::111122223333:root"
  }
}
