include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/clusterfrak-dynamics/terraform-kubernetes-addons.git?ref=v5.8.0"

  before_hook "init" {
    commands = ["init"]
    execute  = ["bash", "-c", "wget -O terraform-provider-kubectl https://github.com/gavinbunney/terraform-provider-kubectl/releases/download/v1.4.2/terraform-provider-kubectl-linux-amd64 && chmod +x terraform-provider-kubectl"]
  }
}

locals {
  env                 = yamldecode(file("${find_in_parent_folders("common_tags.yaml")}"))["Env"]
  aws_region          = yamldecode(file("${find_in_parent_folders("common_values.yaml")}"))["aws_region"]
  default_domain_name = yamldecode(file("${find_in_parent_folders("common_values.yaml")}"))["default_domain_name"]
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

  calico = {
    enabled = true
  }

  alb_ingress = {
    enabled = true
  }

  aws_node_termination_handler = {
    enabled = true
  }

  nginx_ingress = {
    enabled = true
  }

  istio_operator = {
    enabled = true
  }

  cluster_autoscaler = {
    enabled      = true
    cluster_name = dependency.eks.outputs.cluster_id
    extra_values = <<-EXTRA_VALUES
      image:
        repository: eu.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler
      EXTRA_VALUES
  }

  external_dns = {
    enabled = true
  }

  cert_manager = {
    enabled                        = true
    acme_email                     = "kevin@particule.io"
    enable_default_cluster_issuers = true
    allowed_cidrs                  = dependency.vpc.outputs.private_subnets_cidr_blocks
  }

  metrics_server = {
    enabled       = true
    allowed_cidrs = dependency.vpc.outputs.private_subnets_cidr_blocks
  }

  flux = {
    enabled      = true
    extra_values = <<-EXTRA_VALUES
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
    enabled       = true
    allowed_cidrs = dependency.vpc.outputs.private_subnets_cidr_blocks
    extra_values  = <<-EXTRA_VALUES
      grafana:
        deploymentStrategy:
          type: Recreate
        ingress:
          enabled: true
          annotations:
            kubernetes.io/ingress.class: nginx
            cert-manager.io/cluster-issuer: "letsencrypt"
          hosts:
            - grafana.${local.default_domain_name}
          tls:
            - secretName: grafana.${local.default_domain_name}
              hosts:
                - grafana.${local.default_domain_name}
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
          serviceMonitorSelectorNilUsesHelmValues: false
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
    enabled = false
  }

  aws_fluent_bit = {
    enabled = true
  }

  npd = {
    enabled = true
  }

  sealed_secrets = {
    enabled = true
  }

  cni_metrics_helper = {
    enabled = true
  }

  kong = {
    enabled = true
  }

  keycloak = {
    enabled = false
  }

  karma = {
    enabled      = true
    extra_values = <<-EXTRA_VALUES
      ingress:
        enabled: true
        path: /
        annotations:
          kubernetes.io/ingress.class: nginx
          cert-manager.io/cluster-issuer: "letsencrypt"
        hosts:
          - karma.${local.default_domain_name}
        tls:
          - secretName: karma.${local.default_domain_name}
            hosts:
              - karma.${local.default_domain_name}
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
