include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/clusterfrak-dynamics/terraform-kubernetes-addons.git?ref=v5.0.0"

  before_hook "init" {
    commands = ["init"]
    execute  = ["bash", "-c", "wget -O terraform-provider-kubectl https://github.com/gavinbunney/terraform-provider-kubectl/releases/download/v1.2.1/terraform-provider-kubectl-linux-amd64 && chmod +x terraform-provider-kubectl"]
  }
}

locals {
  env        = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_tags.yaml")}"))["Env"]
  aws_region = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_values.yaml")}"))["aws_region"]
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_id              = "cluster-name"
    cluster_oidc_issuer_url = "https://oidc.eks.eu-west-3.amazonaws.com/id/0000000000000000"
  }
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    private_subnets_cidr_blocks = [
      "10.0.0.0/16",
      "192.168.0.0/24"
    ]
  }
}

inputs = {

  cluster-name = dependency.eks.outputs.cluster_id

  aws = {
    "region" = local.aws_region
  }

  eks = {
    "cluster_oidc_issuer_url" = dependency.eks.outputs.cluster_oidc_issuer_url
  }

  nginx_ingress = {
    version                = "0.29.0"
    chart_version          = "1.31.0"
    enabled                = true
    default_network_policy = true
    ingress_cidr           = "0.0.0.0/0"
    use_nlb                = false
    use_l7                 = false
  }

  istio_operator = {
    enabled = false
  }

  cluster_autoscaler = {
    create_iam_resources_kiam = false
    create_iam_resources_irsa = true
    iam_policy_override       = ""
    version                   = "v1.14.7"
    chart_version             = "6.4.0"
    enabled                   = true
    default_network_policy    = true
    cluster_name              = dependency.eks.outputs.cluster_id
  }

  external_dns = {
    create_iam_resources_kiam = false
    create_iam_resources_irsa = true
    iam_policy_override       = ""
    version                   = "0.6.0-debian-10-r0"
    chart_version             = "2.18.0"
    enabled                   = true
    default_network_policy    = true
  }

  cert_manager = {
    create_iam_resources_kiam      = false
    create_iam_resources_irsa      = true
    iam_policy_override            = ""
    version                        = "v0.13.1"
    chart_version                  = "v0.13.1"
    enabled                        = true
    default_network_policy         = true
    acme_email                     = "kevin@particule.io"
    enable_default_cluster_issuers = true
    allowed_cidrs                  = dependency.vpc.outputs.private_subnets_cidr_blocks
  }

  kiam = {
    create_iam_user             = true
    create_iam_resources        = true
    assume_role_policy_override = ""
    version                     = "v3.5"
    chart_version               = "5.7.0"
    enabled                     = false
    default_network_policy      = false
    iam_user                    = ""
  }

  metrics_server = {
    version                = "v0.3.6"
    chart_version          = "2.9.0"
    enabled                = true
    default_network_policy = true
    allowed_cidrs          = dependency.vpc.outputs.private_subnets_cidr_blocks
  }

  flux = {
    create_iam_resources_kiam = false
    create_iam_resources_irsa = true
    version                   = "1.18.0"
    chart_version             = "1.2.0"
    enabled                   = false
    default_network_policy    = true

    extra_values = <<EXTRA_VALUES
git:
  url: "ssh://git@gitlab.com/myrepo/gitops-${local.env}.git"
  pollInterval: "2m"
rbac:
  create: false
registry:
  automationInterval: "2m"
EXTRA_VALUES
  }

  prometheus_operator = {
    chart_version          = "8.7.0"
    enabled                = true
    default_network_policy = true
    allowed_cidrs          = dependency.vpc.outputs.private_subnets_cidr_blocks

    extra_values = <<EXTRA_VALUES
grafana:
  deploymentStrategy:
    type: Recreate
  ingress:
    enabled: false
    annotations:
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: "letsencrypt"
    hosts:
      - grafana.clusterfrak-dynamics.io
    tls:
      - secretName: grafana-clusterfrak-dynamics-io
        hosts:
          - grafana.clusterfrak-dynamics.io
  persistence:
    enabled: true
    storageClassName: gp2
    accessModes:
      - ReadWriteOnce
    size: 10Gi
prometheus:
  prometheusSpec:
    replicas: 1
    retention: 180d
    ruleSelectorNilUsesHelmValues: false
    ruleNamespaceSelector:
      any: true
    serviceMonitorSelectorNilUsesHelmValues: false
    serviceMonitorNamespaceSelector:
      any: true
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
EXTRA_VALUES
  }

  fluentd_cloudwatch = {
    create_iam_resources_kiam        = false
    create_iam_resources_irsa        = true
    default_network_policy           = true
    iam_policy_override              = ""
    chart_version                    = "0.12.1"
    version                          = "v1.7.4-debian-cloudwatch-1.0"
    enabled                          = true
    containers_log_retention_in_days = 180
  }

  npd = {
    chart_version          = "1.6.3"
    version                = "v0.8.0"
    enabled                = true
    default_network_policy = true
  }

  sealed_secrets = {
    chart_version          = "1.7.6"
    version                = "v0.9.7"
    enabled                = true
    default_network_policy = true
  }

  cni_metrics_helper = {
    create_iam_resources_kiam = false
    create_iam_resources_irsa = true
    enabled                   = true
    version                   = "v1.5.5"
    iam_policy_override       = ""
  }

  kong = {
    version                = "1.4"
    chart_version          = "1.2.0"
    enabled                = false
    default_network_policy = true
    ingress_cidr           = "0.0.0.0/0"
  }

  keycloak = {
    chart_version          = "7.0.0"
    version                = "8.0.1"
    enabled                = false
    default_network_policy = true
  }

  karma = {
    chart_version          = "1.4.1"
    version                = "v0.55"
    enabled                = false
    default_network_policy = true
    extra_values           = <<EXTRA_VALUES
ingress:
  enabled: false
  path: /
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: "letsencrypt"
  hosts:
    - karma.clusterfrak-dynamics.io
env:
  - name: ALERTMANAGER_URI
    value: "http://prometheus-operator-alertmanager.monitoring.svc.cluster.local:9093"
  - name: ALERTMANAGER_PROXY
    value: "true"
  - name: FILTERS_DEFAULT
    value: "@state=active severity!=info severity!=none"
EXTRA_VALUES
  }
}

