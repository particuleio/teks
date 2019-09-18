include {
  path = "${find_in_parent_folders()}"
}

dependencies {
  paths = ["../eks-addons", "../eks"]
}

terraform {
  source = "../../../modules//eks-namespaces"

  before_hook "kubeconfig" {
    commands = ["apply", "plan"]
    execute  = ["bash", "-c", "cp ${get_terragrunt_dir()}/../eks/kubeconfig kubeconfig"]
  }
}

locals {
  aws_region = "eu-west-1"
  env        = "sample"
}

inputs = {

aws = {
  "region" = local.aws_region
}

eks = {
  "kubeconfig_path"            = "./kubeconfig"
  "remote_state_bucket"        = "kubernetes-terraform-remote-state"
  "remote_state_key"           = "sample/eks"
  "remote_state_bucket_region" = "eu-west-1"
}

//
// [env]
//
env = local.env

//
// [namespaces]
//
namespaces = [
  {
    "name"                       = "sample-${local.env}"
    "kiam_allowed_regexp"        = "^$"
    "requests.cpu"               = "50"
    "requests.memory"            = "10Gi"
    "pods"                       = "100"
    "count/cronjobs.batch"       = "100"
    "count/ingresses.extensions" = "5"
    "requests.nvidia.com/gpu"    = "0"
    "services.loadbalancers"     = "0"
    "services.nodeports"         = "0"
    "services"                   = "10"
  },
]
}
