locals {
  default_domain_name   = yamldecode(file("../../../../../global_values.yaml"))["default_domain_name"]
  default_domain_suffix = "${local.custom_tags["Env"]}.${local.custom_tags["Project"]}.${local.default_domain_name}"
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
  name = data.terraform_remote_state.eks.outputs.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.eks.cluster_id
}

module "eks-addons" {
  source = "particuleio/addons/kubernetes//modules/aws"

  cluster-name = data.terraform_remote_state.eks.outputs.eks.cluster_id

  tags = merge(
    local.custom_tags
  )

  eks = {
    "cluster_oidc_issuer_url" = data.terraform_remote_state.eks.outputs.eks.cluster_oidc_issuer_url
  }

  aws-ebs-csi-driver = {
    enabled = true
  }

  aws-for-fluent-bit = {
    enabled = true
  }

  aws-load-balancer-controller = {
    enabled = true
  }

  aws-node-termination-handler = {
    enabled = true
  }

  calico = {
    enabled = true
  }

  cert-manager = {
    enabled                   = true
    acme_email                = "kevin@particule.io"
    acme_http01_enabled       = true
    acme_http01_ingress_class = "nginx"
    acme_dns01_enabled        = true
    allowed_cidrs             = data.terraform_remote_state.vpc.outputs.vpc.private_subnets_cidr_blocks
    experimental_csi_driver   = false
  }

  cluster-autoscaler = {
    enabled = true
  }

  cni-metrics-helper = {
    enabled = true
  }

  external-dns = {
    external-dns = {
      enabled = true
    },
  }

  ingress-nginx = {
    enabled       = true
    use_nlb_ip    = true
    allowed_cidrs = data.terraform_remote_state.vpc.outputs.vpc.private_subnets_cidr_blocks
  }

  istio-operator = {
    enabled = true
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
          - karma.${local.default_domain_suffix}
        tls:
          - secretName: karma.${local.default_domain_suffix}
            hosts:
              - karma.${local.default_domain_suffix}
      env:
        - name: ALERTMANAGER_URI
          value: "http://kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local:9093"
        - name: ALERTMANAGER_PROXY
          value: "true"
        - name: FILTERS_DEFAULT
          value: "@state=active severity!=info severity!=none"
      EXTRA_VALUES
  }

  keycloak = {
    enabled = true
  }

  kong = {
    enabled = true
  }

  kube-prometheus-stack = {
    enabled                     = true
    allowed_cidrs               = data.terraform_remote_state.vpc.outputs.vpc.private_subnets_cidr_blocks
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
    enabled              = true
    bucket_force_destroy = true
  }

  metrics-server = {
    enabled       = true
    allowed_cidrs = data.terraform_remote_state.vpc.outputs.vpc.private_subnets_cidr_blocks
  }

  npd = {
    enabled = true
  }

  sealed-secrets = {
    enabled = true
  }

  thanos = {
    enabled              = true
    bucket_force_destroy = true
  }

}

output "eks-addons" {
  value     = module.eks-addons
  sensitive = true
}
