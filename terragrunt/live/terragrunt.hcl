remote_state {
  backend = "s3"

  config = {
    bucket         = "${yamldecode(file("global_values.yaml"))["prefix"]}-${yamldecode(file("global_values.yaml"))["project"]}-tg-state-store"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "${yamldecode(file("global_values.yaml"))["tf_state_bucket_region"]}"
    encrypt        = true
    dynamodb_table = "${yamldecode(file("global_values.yaml"))["prefix"]}-${yamldecode(file("global_values.yaml"))["project"]}-tg-state-lock"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Use this to impersonate a role, useful for EKS when you want a role to be
# the "root" use and not a personal AWS account
# iam_role = "arn:aws:iam::${yamldecode(file("global_values.yaml"))["aws_account_id"]}:role/administrator"
