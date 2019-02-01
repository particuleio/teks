terragrunt = {
  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = ["../eks"]
  }

  terraform {
    source = "../../../modules//eks-addons"
    before_hook "kubeconfig" {
      commands = ["apply","plan"]
      execute = ["bash","-c","cp ${get_tfvars_dir()}/../eks/kubeconfig kubeconfig"]
    }
    before_hook "helm_repo_update" {
      commands = ["apply","plan"]
      execute = ["bash","-c","helm repo update"]
    }
    after_hook "cert_manager_cluster_issuers" {
      commands = ["apply"]
      execute = ["bash","-c","terraform output cert_manager_cluster_issuers 2>/dev/null | kubectl --kubeconfig kubeconfig apply -f - | true"]
    }
  }
}

//
// [provider]
//
aws = {
  "region" = "eu-west-1"
}

eks = {
  "kubeconfig_path" = "./kubeconfig"
  "remote_state_bucket" = "sample-terraform-remote-state"
  "remote_state_key" = "sample/eks"
}

//
// [nginx_ingress]
//
nginx_ingress = {
  version = "0.21.0"
  chart_version = "1.1.2"
  enabled = false
  namespace = "ingress-nginx"
  extra_values = ""
  use_nlb = false
}

//
// [cluster_autoscaler]
//
cluster_autoscaler = {
  use_kiam = false
  version = "v1.3.5"
  chart_version = "0.11.0"
  enabled = false
  namespace = "cluster-autoscaler"
  cluster_name = "sample"
  extra_values = ""
}

//
// [external_dns]
//
external_dns = {
  use_kiam = false
  version = "v0.5.9"
  chart_version = "1.3.0"
  enabled = false
  namespace = "external-dns"
  extra_values = ""
}

//
// [cert_manager]
//
cert_manager = {
  use_kiam = false
  version = "v0.5.2"
  chart_version = "v0.5.2"
  enabled = false
  namespace = "cert-manager"
  extra_values = ""
  acme_email =  "kevin.lefevre@osones.io"
}

//
// [kiam]
//
kiam = {
  version = "v3.0"
  chart_version = "2.0.1-rc6"
  enabled = false
  namespace = "kiam"
  server_use_host_network = "true"
  extra_values = ""
}

//
// [metrics-server]
//
metrics_server = {
  version = "v0.3.1"
  chart_version = "2.0.4"
  enabled = false
  namespace = "metrics-server"
  extra_values = ""
}

//
// [virtual-kubelet]
//
virtual_kubelet = {
  use_kiam = true
  version = "0.7.4"
  enabled = false
  namespace = "virtual-kubelet"
  cpu = "20"
  memory = "40Gi"
  pods = "20"
  operatingsystem = "Linux"
  platformversion = "LATEST"
  assignpublicipv4address = false
  fargate_cluster_name = "sample"
}

//
// [prometheus_operator]
//
prometheus_operator = {
  chart_version = "1.5.1"
  enabled = false
  namespace = "monitoring"
  extra_values = ""
}

//
// [fluentd_cloudwatch]
//
fluentd_cloudwatch = {
  chart_version = "0.7.0"
  version = "v1.3-debian-cloudwatch"
  use_kiam = false
  enabled = false
  namespace = "fluentd-cloudwatch"
  extra_values = ""
  log_group_name = "eks-sample-logs"
}

//
// [node_problem_detector]
//
npd = {
  chart_version = "1.1.4"
  version = "v0.6.2"
  enabled = true
  namespace = "node-problem-detector"
  extra_values = ""
}
