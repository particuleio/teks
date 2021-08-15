include {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "github.com/particuleio/terraform-kubernetes-addons.git//modules/aws?ref=main"
}

generate "provider-local" {
  path      = "provider-local.tf"
  if_exists = "overwrite"
  contents  = file("../../../../../../provider-config/eks-addons/eks-addons.tf")
}

locals {
  vpc = read_terragrunt_config("../../../../../../dependency-blocks/vpc.hcl")
  eks = read_terragrunt_config("../../../../../../dependency-blocks/eks.hcl")
}

inputs = {

  priority-class = {
    create = false
  }

  priority-class-ds = {
    create = false
  }

  cluster-name = local.eks.dependency.eks.outputs.cluster_id

  tags = merge(
    include.locals.custom_tags
  )

  eks = {
    "cluster_oidc_issuer_url" = local.eks.dependency.eks.outputs.cluster_oidc_issuer_url
  }

  # For this to work:
  # * GITHUB_TOKEN should be set
  # * GITHUB_OWNER should be set to your org or username
  flux2 = {
    enabled               = false
    target_path           = "gitops/clusters/${include.locals.env}/${include.locals.name}"
    github_url            = "ssh://git@github.com/particuleio/gitops"
    repository            = "repo"
    branch                = "main"
    repository_visibility = "public"
    version               = "v0.16.2"
    auto_image_update     = true
  }

  ingress-nginx = {
    enabled       = true
    use_nlb_ip    = true
    allowed_cidrs = local.vpc.dependency.vpc.outputs.private_subnets_cidr_blocks
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
    allowed_cidrs               = local.vpc.dependency.vpc.outputs.private_subnets_cidr_blocks
    namespace                   = "telemetry"
    thanos_sidecar_enabled      = true
    thanos_bucket_force_destroy = true
    default_global_requests     = true
    # Using https://github.com/raspbernetes/multi-arch-images
    # Wainting for ARM support in https://github.com/thanos-io/thanos/issues/1851
    extra_values                = <<-EXTRA_VALUES
      grafana:
        image:
          tag: 8.1.1
        deploymentStrategy:
          type: Recreate
        ingress:
          annotations:
            kubernetes.io/tls-acme: "true"
          ingressClassName: nginx
          enabled: true
          hosts:
            - telemetry.${include.locals.default_domain_name}
          tls:
            - secretName: ${include.locals.default_domain_name}
              hosts:
                - telemetry.${include.locals.default_domain_name}
        persistence:
          enabled: true
          accessModes:
            - ReadWriteOnce
          size: 1Gi
      prometheus:
        prometheusSpec:
          thanos:
            baseImage: raspbernetes/thanos
          scrapeInterval: 60s
          replicas: 1
          retention: 2d
          retentionSize: "40GB"
          ruleSelectorNilUsesHelmValues: false
          serviceMonitorSelectorNilUsesHelmValues: false
          podMonitorSelectorNilUsesHelmValues: false
          storageSpec:
            volumeClaimTemplate:
              spec:
                accessModes: ["ReadWriteOnce"]
                resources:
                  requests:
                    storage: 50Gi
          nodeSelector:
            pool: large
          tolerations:
          - key: "dedicated"
            operator: "Equal"
            value: "large"
            effect: "NoSchedule"
      alertmanager:
        alertmanagerSpec:
          replicas: 1
          nodeSelector:
            pool: large
          tolerations:
          - key: "dedicated"
            operator: "Equal"
            value: "large"
            effect: "NoSchedule"
      EXTRA_VALUES
  }

  thanos = {
    enabled                 = true
    namespace               = "telemetry"
    default_global_requests = true
    default_global_limits   = false
    # Using https://github.com/raspbernetes/multi-arch-images
    # Wainting for ARM support in https://github.com/thanos-io/thanos/issues/1851
    extra_values            = <<-EXTRA_VALUES
      image:
        repository: raspbernetes/thanos
        tag: v0.22.0
      compactor:
        retentionResolution5m: 90d
      EXTRA_VALUES
  }
}
