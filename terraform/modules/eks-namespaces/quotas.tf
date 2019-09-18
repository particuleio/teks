resource "kubernetes_resource_quota" "namespace_quota" {
  count = length(var.namespaces)

  metadata {
    name      = "${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}-quota"
    namespace = kubernetes_namespace.namespace.*.metadata.0.name[count.index]
  }

  spec {
    hard = {
      "requests.cpu"               = var.namespaces[count.index]["requests.cpu"]
      "requests.memory"            = var.namespaces[count.index]["requests.memory"]
      "requests.nvidia.com/gpu"    = var.namespaces[count.index]["requests.nvidia.com/gpu"]
      "pods"                       = var.namespaces[count.index]["pods"]
      "count/cronjobs.batch"       = var.namespaces[count.index]["count/cronjobs.batch"]
      "count/ingresses.extensions" = var.namespaces[count.index]["count/ingresses.extensions"]
      "services.loadbalancers"     = var.namespaces[count.index]["services.loadbalancers"]
      "services.nodeports"         = var.namespaces[count.index]["services.nodeports"]
      "services"                   = var.namespaces[count.index]["services"]
    }
  }
}

resource "kubernetes_limit_range" "namespace_limit" {
  count = length(var.namespaces)

  metadata {
    name      = "${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}-quota"
    namespace = kubernetes_namespace.namespace.*.metadata.0.name[count.index]
  }
  spec {
    limit {
      type = "Container"
      default_request = {
        cpu    = "100m"
        memory = "100M"
      }
    }
  }
}
