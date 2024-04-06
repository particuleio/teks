dependencies {
  paths = ["../eks-addons-critical"]
}

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
  source = "github.com/particuleio/terraform-kubernetes-addons.git//modules/aws?ref=v15.3.0"
}

generate "provider-local" {
  path      = "provider-local.tf"
  if_exists = "overwrite"
  contents  = file("../../../../../../provider-config/eks-addons/eks-addons.tf")
}

generate "provider-github" {
  path      = "provider-github.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "github" {
      owner = "${include.root.locals.merged.github_owner}"
    }
  EOF
}

# Should be removed in flux2 is not used
#
generate "provider-flux" {
  path      = "provider-flux.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "flux" {
      kubernetes = {
        host                   = data.aws_eks_cluster.cluster.endpoint
        token                  = data.aws_eks_cluster_auth.cluster.token
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
      }
      git = {
        url = "ssh://git@github.com/${include.root.locals.merged.github_owner}/$${local.flux2.repository}.git"
        ssh = {
          username    = "git"
          private_key = try(tls_private_key.identity[0].private_key_pem, null)
        }
      }
    }
  EOF
}

inputs = {

  priority-class = {
    name = basename(get_terragrunt_dir())
  }

  priority-class-ds = {
    name = "${basename(get_terragrunt_dir())}-ds"
  }

  cluster-name = dependency.eks.outputs.cluster_name

  tags = merge(
    include.root.locals.custom_tags
  )

  eks = {
    "cluster_oidc_issuer_url" = dependency.eks.outputs.cluster_oidc_issuer_url
    "oidc_provider_arn"       = dependency.eks.outputs.oidc_provider_arn
    "cluster_endpoint"        = dependency.eks.outputs.cluster_endpoint
  }

  cert-manager = {
    enabled                   = true
    acme_http01_enabled       = true
    acme_dns01_enabled        = true
    acme_http01_ingress_class = "nginx"
    extra_values              = <<-EXTRA_VALUES
      ingressShim:
        defaultIssuerName: letsencrypt
        defaultIssuerKind: ClusterIssuer
        defaultIssuerGroup: cert-manager.io
      EXTRA_VALUES
  }

  cluster-autoscaler = {
    enabled      = true
    version      = "v1.26.3"
    extra_values = <<-EXTRA_VALUES
    image:
      repository: registry.k8s.io/autoscaling/cluster-autoscaler
    extraArgs:
      scale-down-utilization-threshold: 0.7
    EXTRA_VALUES
  }

  # For this to work:
  # * GITHUB_TOKEN should be set
  flux2 = {
    enabled    = true
    path       = "gitops/clusters/${include.root.locals.merged.env}/${dependency.eks.outputs.cluster_name}"
    repository = "teks-gitops"
    branch     = "main"
    version    = "v2.0.0-rc.5"
  }

  kube-prometheus-stack = {
    enabled                           = true
    allowed_cidrs                     = dependency.vpc.outputs.intra_subnets_cidr_blocks
    thanos_sidecar_enabled            = true
    thanos_bucket_force_destroy       = true
    grafana_create_iam_resources_irsa = true
    extra_values                      = <<-EXTRA_VALUES
      grafana:
        image:
          tag: 9.5.2
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
          nodeSelector:
            kubernetes.io/arch: amd64
          scrapeInterval: 60s
          retention: 2d
          retentionSize: "10GB"
          ruleSelectorNilUsesHelmValues: false
          serviceMonitorSelectorNilUsesHelmValues: false
          podMonitorSelectorNilUsesHelmValues: false
          probeSelectorNilUsesHelmValues: false
          storageSpec:
            volumeClaimTemplate:
              spec:
                accessModes: ["ReadWriteOnce"]
                resources:
                  requests:
                    storage: 10Gi
          resources:
            requests:
              cpu: 1
              memory: 2Gi
            limits:
              cpu: 2
              memory: 2Gi
      EXTRA_VALUES
  }

  loki-stack = {
    enabled              = true
    bucket_force_destroy = true
    extra_values         = <<-VALUES
      resources:
        requests:
          cpu: 1
          memory: 2Gi
        limits:
          cpu: 2
          memory: 4Gi
      loki:
        limits_config:
          ingestion_rate_mb: 320
          ingestion_burst_size_mb: 512
          max_streams_per_user: 100000
        chunk_store_config:
          max_look_back_period: 2160h
        table_manager:
          retention_deletes_enabled: true
          retention_period: 2160h
      ingress:
        enabled: true
        annotations:
          kubernetes.io/tls-acme: "true"
          nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
          nginx.ingress.kubernetes.io/auth-tls-secret: "telemetry/loki-ca"
        hosts:
          - logz.${include.root.locals.merged.default_domain_name}
        tls:
          - secretName: logz.${include.root.locals.merged.default_domain_name}
            hosts:
              - logz.${include.root.locals.merged.default_domain_name}
        VALUES
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
          days = 365
        }
      },
    ]
  }

  ingress-nginx = {
    enabled       = true
    use_nlb_ip    = true
    allowed_cidrs = dependency.vpc.outputs.intra_subnets_cidr_blocks
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
            cpu: 300m
            memory: 128Mi
        service:
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: preserve_client_ip.enabled=true
      defaultBackend:
        enabled: true
        replicaCount: 2
        minAvailable: 0
        nodeSelector:
          kubernetes.io/arch: amd64
      EXTRA_VALUES
  }

  promtail = {
    enabled = true
    wait    = false
  }

  thanos = {
    enabled              = true
    bucket_force_destroy = true
    # Waiting for ARM support https://github.com/bitnami/charts/issues/7305
    extra_values = <<-EXTRA_VALUES
      query:
        nodeSelector:
          kubernetes.io/arch: amd64
      queryFrontend:
        nodeSelector:
          kubernetes.io/arch: amd64
      bucketweb:
        nodeSelector:
          kubernetes.io/arch: amd64
      compactor:
        nodeSelector:
          kubernetes.io/arch: amd64
      storegateway:
        nodeSelector:
          kubernetes.io/arch: amd64
      ruler:
        nodeSelector:
          kubernetes.io/arch: amd64
      receive:
        nodeSelector:
          kubernetes.io/arch: amd64
      receiveDistributor:
        nodeSelector:
          kubernetes.io/arch: amd64
      EXTRA_VALUES
  }
}
