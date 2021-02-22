provider "aws" {
  region = yamldecode(file("../global_values.yaml"))["tf_state_bucket_region"]
}
