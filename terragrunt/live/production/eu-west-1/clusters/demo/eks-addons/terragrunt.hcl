include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

include "vpc" {
  path           = "../../../../../../dependency-blocks/vpc.hcl"
  expose         = true
  merge_strategy = "deep"
}

include "eks" {
  path           = "../../../../../../dependency-blocks/eks.hcl"
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "github.com/particuleio/terraform-kubernetes-addons.git//modules/aws?ref=v2.41.0"
}

generate "provider-local" {
  path      = "provider-local.tf"
  if_exists = "overwrite"
  contents  = file("../../../../../../provider-config/eks-addons/eks-addons.tf")
}

inputs = {

  priority-class = {
    name = basename(get_terragrunt_dir())
  }

  priority-class-ds = {
    name = "${basename(get_terragrunt_dir())}-ds"
  }

  cluster-name = dependency.eks.outputs.cluster_id

  tags = merge(
    include.root.locals.custom_tags
  )

  eks = {
    "cluster_oidc_issuer_url" = dependency.eks.outputs.cluster_oidc_issuer_url
  }

  cert-manager = {
    enabled             = true
    acme_http01_enabled = true
    acme_dns01_enabled  = true
    extra_values        = <<-EXTRA_VALUES
      ingressShim:
        defaultIssuerName: letsencrypt
        defaultIssuerKind: ClusterIssuer
        defaultIssuerGroup: cert-manager.io
      EXTRA_VALUES
  }

  cluster-autoscaler = {
    enabled      = true
    version      = "v1.21.0"
    extra_values = <<-EXTRA_VALUES
      extraArgs:
        scale-down-utilization-threshold: 0.7
      EXTRA_VALUES
  }

  external-dns = {
    external-dns = {
      enabled = true
    }
  }

  # For this to work:
  # * GITHUB_TOKEN should be set
  flux2 = {
    enabled               = false
    target_path           = "gitops/clusters/${include.root.locals.merged.env}/${include.root.locals.merged.name}"
    github_url            = "ssh://git@github.com/owner/repo"
    repository            = "repo"
    branch                = "main"
    repository_visibility = "private"
    version               = "v0.24.1"
    auto_image_update     = true
  }

  ingress-nginx = {
    enabled       = true
    use_nlb_ip    = true
    allowed_cidrs = dependency.vpc.outputs.private_subnets_cidr_blocks
    extra_values  = <<-EXTRA_VALUES
      controller:
        ingressClassResource:
          enabled: true
          default: true
        replicaCount: 2
        minAvailable: 1
        kind: "Deployment"
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
      EXTRA_VALUES
  }

  kube-prometheus-stack = {
    enabled                     = true
    allowed_cidrs               = dependency.vpc.outputs.private_subnets_cidr_blocks
    thanos_sidecar_enabled      = true
    thanos_bucket_force_destroy = true
    extra_values                = <<-EXTRA_VALUES
      grafana:
        image:
          tag: 8.3.3
        deploymentStrategy:
          type: Recreate
        ingress:
          annotations:
            kubernetes.io/tls-acme: "true"
          ingressClassName: nginx
          enabled: true
          hosts:
            - telemetry.${include.root.locals.merged.default_domain_name}
          tls:
            - secretName: ${include.root.locals.merged.default_domain_name}
              hosts:
                - telemetry.${include.root.locals.merged.default_domain_name}
        persistence:
          enabled: true
          accessModes:
            - ReadWriteOnce
          size: 1Gi
      prometheus:
        prometheusSpec:
          scrapeInterval: 60s
          retention: 2d
          retentionSize: "10GB"
          ruleSelectorNilUsesHelmValues: false
          serviceMonitorSelectorNilUsesHelmValues: false
          podMonitorSelectorNilUsesHelmValues: false
          storageSpec:
            volumeClaimTemplate:
              spec:
                accessModes: ["ReadWriteOnce"]
                resources:
                  requests:
                    storage: 10Gi
      EXTRA_VALUES
  }

  loki-stack = {
    enabled              = true
    bucket_force_destroy = true

    bucket_lifecycle_rule = [
      {
        id      = "log"
        enabled = true
        transition = [
          {
            days          = 14
            storage_class = "INTELLIGENT_TIERING"
          },
        ]
        expiration = {
          days = 30
        }
      },
    ]
  }

  promtail = {
    enabled = true
  }

  thanos = {
    enabled              = true
    bucket_force_destroy = true
  }
}
