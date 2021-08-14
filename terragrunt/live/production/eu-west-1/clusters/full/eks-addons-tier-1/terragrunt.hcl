include {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "github.com/particuleio/terraform-kubernetes-addons.git//modules/aws?ref=v2.14.0"
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

  cluster-name = local.eks.dependency.eks.outputs.cluster_id

  tags = merge(
    include.locals.custom_tags
  )

  eks = {
    "cluster_oidc_issuer_url" = local.eks.dependency.eks.outputs.cluster_oidc_issuer_url
  }

  aws-ebs-csi-driver = {
    enabled          = true
    is_default_class = true
    wait             = true
    use_encryption   = true
    use_kms          = true
  }

  aws-load-balancer-controller = {
    enabled = true
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
    enabled = true
    version = "v1.21.0"
  }

  external-dns = {
    external-dns = {
      enabled = true
      # Waiting for https://github.com/kubernetes-sigs/external-dns/pull/2208
      extra_values = <<-EXTRA_VALUES
        image:
          repository: k8s.gcr.io/external-dns/external-dns
          tag: v0.9.0
        EXTRA_VALUES
    },
  }

  metrics-server = {
    enabled       = true
    allowed_cidrs = local.vpc.dependency.vpc.outputs.private_subnets_cidr_blocks

    # Waiting for https://github.com/kubernetes-sigs/metrics-server/issues/572
    extra_values = <<-EXTRA_VALUES
      securePort: 443
      image:
        repository: k8s.gcr.io/metrics-server/metrics-server
        tag: v0.5.0
      command: ["/metrics-server"]
      extraVolumes:
        - name: tmp-dir
          emptyDir: {}
      extraVolumeMounts:
        - name: tmp-dir
          mountPath: /tmp
      extraArgs:
        cert-dir: /tmp
        kubelet-preferred-address-types: InternalIP,ExternalIP,Hostname
        kubelet-use-node-status-port:
        metric-resolution: 15s
      EXTRA_VALUES
  }

  npd = {
    # Waiting for https://github.com/kubernetes/node-problem-detector/pull/588
    enabled = false
  }

}
