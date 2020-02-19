variable "psp_privileged_ns" {
  default = []
  type    = list
}

data "kubectl_path_documents" "manifests" {
  pattern      = "./manifests/*.yaml"
  vars         = {
    namespaces = join(",", var.psp_privileged_ns)
  }
}

resource "kubectl_manifest" "manifests" {
  count            = length(data.kubectl_path_documents.manifests.documents)
  yaml_body        = element(data.kubectl_path_documents.manifests.documents, count.index)
  wait_for_rollout = false
  force_new        = false
}
