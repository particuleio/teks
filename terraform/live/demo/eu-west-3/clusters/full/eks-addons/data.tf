data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "${yamldecode(file("../../../../../global_values.yaml"))["prefix"]}-${yamldecode(file("../../../../../global_values.yaml"))["project"]}-tf-state-lock"
    key    = "${trimprefix(split("live", path.cwd)[1], "/")}/../vpc/terraform.tfstate"
    region = yamldecode(file("../../../../../global_values.yaml"))["tf_state_bucket_region"]
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "${yamldecode(file("../../../../../global_values.yaml"))["prefix"]}-${yamldecode(file("../../../../../global_values.yaml"))["project"]}-tf-state-lock"
    key    = "${trimprefix(split("live", path.cwd)[1], "/")}/../eks/terraform.tfstate"
    region = yamldecode(file("../../../../../global_values.yaml"))["tf_state_bucket_region"]
  }
}
