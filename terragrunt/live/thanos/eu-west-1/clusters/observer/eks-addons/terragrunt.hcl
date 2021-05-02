include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/particuleio/terraform-kubernetes-addons.git//modules/aws?ref=main"
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

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"
    }
    provider "kubectl" {
      host                   = data.aws_eks_cluster.cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
      token                  = data.aws_eks_cluster_auth.cluster.token
      load_config_file       = false
    }
    provider "kubernetes" {
      host                   = data.aws_eks_cluster.cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
      token                  = data.aws_eks_cluster_auth.cluster.token
    }
    provider "helm" {
      kubernetes {
        host                   = data.aws_eks_cluster.cluster.endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
        token                  = data.aws_eks_cluster_auth.cluster.token
      }
    }
    data "aws_eks_cluster" "cluster" {
      name = var.cluster-name
    }
    data "aws_eks_cluster_auth" "cluster" {
      name = var.cluster-name
    }
  EOF
}


locals {
  aws_region = yamldecode(file("${find_in_parent_folders("region_values.yaml")}"))["aws_region"]
  custom_tags = merge(
    yamldecode(file("${find_in_parent_folders("global_tags.yaml")}")),
    yamldecode(file("${find_in_parent_folders("env_tags.yaml")}"))
  )
  default_domain_name   = yamldecode(file("${find_in_parent_folders("global_values.yaml")}"))["default_domain_name"]
  default_domain_suffix = "${local.custom_tags["Env"]}.${local.custom_tags["Project"]}.${local.default_domain_name}"
}

inputs = {

  cluster-name = dependency.eks.outputs.cluster_id

  tags = merge(
    local.custom_tags
  )

  eks = {
    "cluster_oidc_issuer_url" = dependency.eks.outputs.cluster_oidc_issuer_url
  }

  aws-ebs-csi-driver = {
    enabled          = true
    is_default_class = true
  }

  aws-for-fluent-bit = {
    enabled = true
  }

  aws-load-balancer-controller = {
    enabled = true
  }

  aws-node-termination-handler = {
    enabled = false
  }

  calico = {
    enabled = true
  }

  cert-manager = {
    enabled                   = true
    acme_email                = "cert@particule.io"
    acme_http01_enabled       = true
    acme_http01_ingress_class = "nginx"
    acme_dns01_enabled        = true
    allowed_cidrs             = dependency.vpc.outputs.private_subnets_cidr_blocks
    experimental_csi_driver   = true
  }

  cluster-autoscaler = {
    enabled = true
  }

  cni-metrics-helper = {
    enabled = false
  }

  external-dns = {
    external-dns = {
      enabled = true
    },
  }

  ingress-nginx = {
    enabled       = true
    use_nlb_ip    = true
    allowed_cidrs = dependency.vpc.outputs.private_subnets_cidr_blocks
  }

  istio-operator = {
    enabled = false
  }

  karma = {
    enabled = false
  }

  keycloak = {
    enabled = false
  }

  kong = {
    enabled = false
  }

  kube-prometheus-stack = {
    enabled                     = true
    allowed_cidrs               = dependency.vpc.outputs.private_subnets_cidr_blocks
    thanos_sidecar_enabled      = true
    thanos_bucket_force_destroy = true
    extra_values                = <<-EXTRA_VALUES
      grafana:
        deploymentStrategy:
          type: Recreate
        ingress:
          enabled: true
          annotations:
            kubernetes.io/ingress.class: nginx
            cert-manager.io/cluster-issuer: "letsencrypt"
          hosts:
            - grafana.${local.default_domain_suffix}
          tls:
            - secretName: grafana.${local.default_domain_suffix}
              hosts:
                - grafana.${local.default_domain_suffix}
        persistence:
          enabled: true
          storageClassName: ebs-sc
          accessModes:
            - ReadWriteOnce
          size: 1Gi
      prometheus:
        prometheusSpec:
          replicas: 1
          retention: 2d
          retentionSize: "6GB"
          ruleSelectorNilUsesHelmValues: false
          serviceMonitorSelectorNilUsesHelmValues: false
          podMonitorSelectorNilUsesHelmValues: false
          storageSpec:
            volumeClaimTemplate:
              spec:
                storageClassName: ebs-sc
                accessModes: ["ReadWriteOnce"]
                resources:
                  requests:
                    storage: 10Gi
      EXTRA_VALUES
  }

  loki-stack = {
    enabled              = false
    bucket_force_destroy = true
  }

  metrics-server = {
    enabled       = true
    allowed_cidrs = dependency.vpc.outputs.private_subnets_cidr_blocks
  }

  npd = {
    enabled = false
  }

  sealed-secrets = {
    enabled = false
  }

  thanos = {
    enabled              = true
    generate_ca          = true
    bucket_force_destroy = true
  }

  thanos-tls-querier = {
    "observee" = {
      enabled                 = true
      default_global_requests = true
      default_global_limits   = false
      stores = [
        "thanos-sidecar.${local.default_domain_suffix}:443"
      ]
    }
  }

  thanos-storegateway = {
    "observee" = {
      enabled                 = true
      default_global_requests = true
      default_global_limits   = false
      bucket                  = "thanos-store-pio-thanos-observee"
      region                  = "eu-west-3"
    }
  }
}
