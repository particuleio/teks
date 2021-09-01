include {
  path   = find_in_parent_folders()
  expose = true
}

dependencies {
  paths = ["../eks"]
}

terraform {
  source = "github.com/particuleio/terraform-kubernetes-addons.git//modules/aws?ref=v2.17.0"
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
    name = basename(get_terragrunt_dir())
  }

  priority-class-ds = {
    name = "${basename(get_terragrunt_dir())}-ds"
  }

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

  tigera-operator = {
    # Waiting for https://github.com/tigera/operator/issues/1246
    enabled = false
  }

}
