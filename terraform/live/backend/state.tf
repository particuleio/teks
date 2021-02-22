module "tfstate-backend" {
  source                             = "cloudposse/tfstate-backend/aws"
  version                            = "~> 0.33"
  attributes                         = ["${yamldecode(file("../global_values.yaml"))["prefix"]}-${yamldecode(file("../global_values.yaml"))["project"]}-tf-state-store"]
  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  s3_bucket_name                     = "${yamldecode(file("../global_values.yaml"))["prefix"]}-${yamldecode(file("../global_values.yaml"))["project"]}-tf-state-lock"
  force_destroy                      = false
}
