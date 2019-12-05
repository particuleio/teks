include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/clusterfrak-dynamics/terraform-aws-iam-roles?ref=v1.0.1"
}

locals {
  aws_region  = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_values.yaml")}"))["aws_region"]
  env         = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_tags.yaml")}"))["Env"]
  custom_tags = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_tags.yaml")}"))
  prefix      = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_values.yaml")}"))["prefix"]
}

dependency "eks-addons" {
  config_path = "../eks-addons"

  mock_outputs = {
    kiam-server-role-arn = ["arn:aws:iam::000000000000:role/mock-role"]
  }
}

inputs = {

  env = local.env

  aws = {
    "region" = local.aws_region
  }

  iam_roles = [
    {
      name   = "${local.prefix}-s3-access-${local.env}"
      policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowFullAccesstoS3",
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
              "arn:aws:s3:::examplebucket",
              "arn:aws:s3:::examplebucket/*"
            ]
        }
    ]
}
POLICY
      assume_role_policy = <<ASSUME_ROLE_POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${dependency.eks-addons.outputs.kiam-server-role-arn[0]}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
ASSUME_ROLE_POLICY
    }
  ]
}
