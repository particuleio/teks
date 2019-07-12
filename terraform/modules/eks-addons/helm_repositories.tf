data "helm_repository" "flux" {
  name = "flux"
  url  = "https://raw.githubusercontent.com/fluxcd/flux/gh-pages/"
}

data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com/"
}

data "helm_repository" "incubator" {
  name = "incubator"
  url  = "https://kubernetes-charts-incubator.storage.googleapis.com/"
}

