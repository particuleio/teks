include {
  path   = find_in_parent_folders()
  expose = true
}

dependencies {
  paths = ["../eks"]
}

terraform {
  source = "github.com/particuleio/terraform-kubernetes-addons.git//modules/aws?ref=v2.17.0"

  after_hook "kubeconfig" {
    commands = ["apply"]
    execute  = ["bash", "-c", "cd ${get_terragrunt_dir()}/../eks && terragrunt output --raw kubeconfig 2>/dev/null > ${get_terragrunt_dir()}/kubeconfig"]
  }

  after_hook "vpc-cni-prefix-delegation" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig set env daemonset aws-node -n kube-system ENABLE_PREFIX_DELEGATION=true"]
  }

  after_hook "vpc-cni-prefix-warm-prefix" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig set env daemonset aws-node -n kube-system WARM_PREFIX_TARGET=1"]
  }
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
    name  = basename(get_terragrunt_dir())
    value = "90000"
  }

  priority-class-ds = {
    name   = "${basename(get_terragrunt_dir())}-ds"
    values = "100000"
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
        registry: k8s.gcr.io
        repository: metrics-server/metrics-server
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
