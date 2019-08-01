include {
  path = "${find_in_parent_folders()}"
}

dependencies {
  paths = ["../eks"]
}

terraform {
  source = "../../../modules//eks-addons"

  before_hook "kubeconfig" {
    commands = ["apply", "plan"]
    execute  = ["bash", "-c", "cp ${get_terragrunt_dir()}/../eks/kubeconfig kubeconfig"]
  }

  before_hook "helm_repo_update" {
    commands = ["apply", "plan"]
    execute  = ["bash", "-c", "helm repo update"]
  }
}

inputs = {
  //
  // [provider]
  //
  aws = {
    "region" = "eu-west-1"
  }

  eks                            = {
    "kubeconfig_path"            = "./kubeconfig"
    "remote_state_bucket"        = "teks-terraform-remote-state"
    "remote_state_key"           = "sample/eks"
    "remote_state_bucket_region" = "eu-west-1"
  }

  //
  // [nginx_ingress]
  //
  nginx_ingress = {
    version                = "0.25.0"
    chart_version          = "1.11.5"
    enabled                = false
    default_network_policy = false
    ingress_cidr           = "0.0.0.0/0"
    namespace              = "ingress-nginx"
    extra_values           = <<EXTRA_VALUES
EXTRA_VALUES

    use_nlb = true
    use_l7  = false
  }

  //
  // [cluster_autoscaler]
  //
  cluster_autoscaler = {
    use_kiam               = false
    version                = "v1.13.6"
    chart_version          = "3.1.0"
    enabled                = false
    default_network_policy = false
    namespace              = "cluster-autoscaler"
    cluster_name           = "sample"
    extra_values           = ""
  }

  //
  // [external_dns]
  //
  external_dns = {
    use_kiam               = false
    version                = "0.5.15"
    chart_version          = "2.4.2"
    enabled                = false
    default_network_policy = false
    namespace              = "external-dns"
    extra_values           = <<EXTRA_VALUES
EXTRA_VALUES
  }

  //
  // [cert_manager]
  //
  cert_manager = {
    use_kiam                        = false
    version                         = "v0.9.0"
    chart_version                   = "v0.9.0"
    enabled                         = false
    default_network_policy          = false
    namespace                       = "cert-manager"
    extra_values                    = ""
    acme_email                      = "example@email.com"
    enable_default_cluster_issuers  = false
  }

  //
  // [kiam]
  //
  kiam = {
    version                 = "v3.3"
    chart_version           = "2.5.1"
    enabled                 = false
    default_network_policy  = false
    namespace               = "kiam"
    server_use_host_network = "true"
    extra_values            = ""
  }

  //
  // [metrics-server]
  //
  metrics_server = {
    version                    = "v0.3.3"
    chart_version              = "2.8.2"
    enabled                    = false
    default_network_policy     = false
    namespace                  = "metrics-server"
    extra_values               = ""
    control_plane_private_cidr = ""
    control_plane_public_cidr  = ""
  }

  //
  // [flux]
  //
  flux = {
    version                = "1.13.3"
    chart_version          = "0.11.0"
    enabled                = false
    default_network_policy = false
    namespace              = "flux"
    allowed_namespaces     = ""

    extra_values = <<EXTRA_VALUES
  git:
    url: "ssh://git@github.com/YOUR_REPO"
    pollInterval: "1m"
  helmOperator:
    create: false
    tillerNamespace: "flux"
    allowNamespace: "flux"
  registry:
    excludeImage: "*"
  rbac:
    create: false
  syncGarbageCollection:
    enabled: true
    dry: false
EXTRA_VALUES
  }

  //
  // [virtual-kubelet]
  //
  virtual_kubelet = {
    use_kiam                = true
    version                 = "0.9.1"
    enabled                 = false
    default_network_policy  = false
    namespace               = "virtual-kubelet"
    cpu                     = "20"
    memory                  = "40Gi"
    pods                    = "20"
    operatingsystem         = "Linux"
    platformversion         = "LATEST"
    assignpublicipv4address = false
    fargate_cluster_name    = "sample"
  }

  //
  // [prometheus_operator]
  //
  prometheus_operator = {
    chart_version          = "6.3.1"
    enabled                = false
    default_network_policy = false
    namespace              = "monitoring"

    extra_values = <<EXTRA_VALUES
  grafana:
    ingress:
      enabled: true
      annotations:
        certmanager.k8s.io/acme-challenge-type: dns01
        certmanager.k8s.io/acme-dns01-provider: route53
        certmanager.k8s.io/cluster-issuer: letsencrypt
        kubernetes.io/ingress.class: nginx
        kubernetes.io/tls-acme: "true"
      hosts:
        - grafana.eks.example.domain
      tls:
        - secretName: grafana-eks-example-domain
          hosts:
            - grafana.eks.example.domain
EXTRA_VALUES
  }

  //
  // [fluentd_cloudwatch]
  //
  fluentd_cloudwatch = {
    chart_version          = "0.10.2"
    version                = "v1.4.2-debian-cloudwatch-1.1"
    use_kiam               = false
    enabled                = false
    default_network_policy = false
    namespace              = "fluentd-cloudwatch"
    extra_values           = ""
    log_group_name         = "eks-sample-logs"
  }

  //
  // [node_problem_detector]
  //
  npd = {
    chart_version          = "1.5.0"
    version                = "v0.6.3"
    enabled                = false
    default_network_policy = false
    namespace              = "node-problem-detector"
    extra_values           = ""
  }

  //
  // [sealed_secrets]
  //
  sealed_secrets = {
    chart_version          = "1.3.2"
    version                = "v0.8.1"
    enabled                = false
    default_network_policy = false
    namespace              = "sealed-secrets"
    extra_values           = ""
  }

  //
  // [istio]
  //
  istio = {
    chart_version_init     = "1.2.2"
    chart_version          = "1.2.2"
    enabled_init           = false
    enabled                = false
    default_network_policy = false
    namespace              = "istio-system"
    extra_values_init      = ""
    extra_values           = <<EXTRA_VALUES
  gateways:
    istio-ingressgateway:
      sds:
        enabled: true
      serviceAnnotations:
        service.beta.kubernetes.io/aws-load-balancer-type: nlb
  global:
    k8sIngress:
      enabled: true
      enabledHttps: true
      gatewayName: ingressgateway
EXTRA_VALUES
  }
}
