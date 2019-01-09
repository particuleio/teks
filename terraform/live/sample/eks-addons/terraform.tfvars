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
      commands = ["apply"]
      execute = ["bash","-c","cp ${get_tfvars_dir()}/../eks/kubeconfig kubeconfig"]
    }
    after_hook "cert_manager_cluster_issuers" {
      commands = ["apply"]
      execute = ["bash","-c","terraform output cert_manager_cluster_issuers 2>/dev/null | kubectl --kubeconfig kubeconfig apply -f -"]
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
  enabled = true
  namespace = "ingress-nginx"
  extra_values = ""
}

//
// [cluster_autoscaler]
//
cluster_autoscaler = {
  version = "v1.3.5"
  chart_version = "0.11.0"
  enabled = true
  namespace = "cluster-autoscaler"
  cluster_name = "sample"
  extra_values = ""
}

//
// [external_dns]
//
external_dns = {
  version = "v0.5.9"
  chart_version = "1.3.0"
  enabled = true
  namespace = "external-dns"
  extra_values = ""
}

//
// [cert_manager]
//
cert_manager = {
  version = "v0.5.2"
  chart_version = "v0.5.2"
  enabled = true
  namespace = "cert-manager"
  extra_values = ""
  acme_email =  "kevin.lefevre@osones.io"
}

//
// [kiam]
//
kiam = {
  version = "v3.0"
  chart_version = "2.0.1-rc3"
  enabled = true
  namespace = "kiam"
  extra_values = ""
}

//
// [metrics-server]
//
metrics_server = {
  version = "v0.3.1"
  chart_version = "2.0.4"
  enabled = true
  namespace = "metrics-server"
  extra_values = ""
}

//
// [virtual-kubelet]
//
virtual_kubelet = {
  version = "0.7.4"
  enabled = true
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
  enabled = true
  namespace = "monitoring"
  extra_values = <<VALUES
grafana:
  ingress:
    enabled: true
    annotations:
      certmanager.k8s.io/acme-challenge-type: dns01
      certmanager.k8s.io/acme-dns01-provider: route53
      certmanager.k8s.io/cluster-issuer: letsencrypt
      kubernetes.io/ingress.class: nginx
      kubernetes.io/tls-acme: "true"
    hosts:
      - grafana.archifleks.net
    tls:
      - secretName: grafana-archifleks-net
        hosts:
          - grafana.archifleks.net
VALUES
}
