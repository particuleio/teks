# tEKS

[![Build Status](https://travis-ci.com/clusterfrak-dynamics/teks.svg?branch=master)](https://travis-ci.com/clusterfrak-dynamics/teks)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fclusterfrak-dynamics%2Fteks.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fclusterfrak-dynamics%2Fteks?ref=badge_shield)

tEKS is a set of Terraform / Terragrunt modules designed to get you everything you need to run a production EKS cluster on AWS. It ships with sensible defaults, and add a lot of common addons with their configurations that work out of the box.

## Modules

* [`eks`](https://github.com/clusterfrak-dynamics/teks/tree/master/terraform/modules/eks-addons): bootstrap a managed EKS cluster with a managed or existing VPC. Similar to the [official module](https://github.com/terraform-aws-modules/terraform-aws-eks).
* [`eks-addons`](https://github.com/clusterfrak-dynamics/teks/tree/master/terraform/modules/eks-addons): provides various addons that are often used on Kubernetes and specifically on EKS.
* [`eks-namespaces`](https://github.com/clusterfrak-dynamics/teks/tree/master/terraform/modules/eks-namespaces): allows administrator to manage namespaces and quotas from a centralized configuration with Terraform.

## Roadmap

When this projet started, it did not rely on the official [Terraform EKS module](https://github.com/terraform-aws-modules/terraform-aws-eks) which is now quite stable and allows advanced configurations. The goal is now to migrate parts of this project to the upstream one and offloading part of the work to official modules and integrating them with Terragrunt:

* [AWS VPC](https://github.com/terraform-aws-modules/terraform-aws-vpc)
* [EKS](https://github.com/terraform-aws-modules/terraform-aws-eks)
* [`eks`](https://github.com/clusterfrak-dynamics/teks/tree/master/terraform/modules/eks) module will be kept for compatibility and all the feature will be PR upstream if they do not already exist.

[eks-addons](https://github.com/clusterfrak-dynamics/teks/tree/master/terraform/modules/eks-addons) is now decoupled from `eks` module. It will soon be compatible with [upstream module](https://github.com/terraform-aws-modules/terraform-aws-eks). v3.X is working toward this goal.

## Branches

* [`master`](https://github.com/clusterfrak-dynamics/teks/tree/master): Backward incompatible with v1.X but compatible with v2.X, releases bumped to v3.X because a lot has changed.
* [`release-1.X`](https://github.com/clusterfrak-dynamics/teks/tree/release-1.X): Compatible with Terraform < 0.12 and Terragrunt < 0.19. Be sure to target the same modules version.
* [`release-2.X`](https://github.com/clusterfrak-dynamics/teks/tree/release-2.X): Compatible with Terraform >= 0.12 and Terragrunt >= 0.19. Be sure to target the same modules version.

### Upgrading from older version

#### `v1.X` to `v2.X`

`v1.X` is compatible with Terraform < 0.12 and Terragrunt < 0.19. The upgrade path to v2.x is simple:

* update tooling locally
* migrate from `terraform.tfvars` files to `terragrunt.hcl` as shown in `live` folder

#### `v2.X` to `v3.X`

`v2.X` and `v3.X` are not really incompatible per se, there was a lot of changes and a careful migration is needed to avoid breaking running cluster so a change of version was simpler.

* update the `eks-addons` module.
* run the `eks-addons` module with the Kiam configuration if needed.
* `eks-addons` module will create the new IAM user and policies.
* update the `eks` module.
* run the `eks` module.
* `eks` will destroy the previous IAM role and policies.

## Main features

* Node pools with customizable labels / taints
* Fully customizable kubelet args
* Supports new or existing VPC
* Calico for network policies
* Common addons with associated IAM permissions if needed:
  * [cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler): scale worker nodes based on workload.
  * [external-dns](https://github.com/kubernetes-incubator/external-dns): sync ingress and service records in route53.
  * [cert-manager](https://github.com/jetstack/cert-manager): automatically generate TLS certificates, supports ACME v2.
  * [kiam](https://github.com/uswitch/kiam): prevents pods to access EC2 metadata and enables pods to assume specific AWS IAM roles.
  * [nginx-ingress](https://github.com/kubernetes/ingress-nginx): processes *Ingress* object and acts as a HTTP/HTTPS proxy (compatible with cert-manager).
  * [metrics-server](https://github.com/kubernetes-incubator/metrics-server): enable metrics API and horizontal pod scaling (HPA).
  * [prometheus-operator](https://github.com/coreos/prometheus-operator): Monitoring / Alerting / Dashboards.
  * [virtual-kubelet](https://github.com/coreos/prometheus-operator): enables using ECS Fargate as a provider to run workload without EC2 instances.
  * [fluentd-cloudwatch](https://github.com/helm/charts/tree/master/incubator/fluentd-cloudwatch): forwards logs to AWS Cloudwatch.
  * [node-problem-detector](https://github.com/kubernetes/node-problem-detector): Forwards node problems to Kubernetes events
  * [flux](https://github.com/weaveworks/flux): Continous Delivery with Gitops workflow.
  * [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets): Technology agnostic, store secrets on git.
  * [istio](https://istio.io): Service mesh for Kubernetes.
  * [cni-metrics-helper](https://docs.aws.amazon.com/eks/latest/userguide/cni-metrics-helper.html): Provides cloudwatch metrics for VPC CNI plugins.
  * [kong](https://konghq.com/kong): API Gateway ingress controller.
  * [rancher](https://rancher.com/): UI for easy cluster management.
  * [keycloak](https://www.keycloak.org/) : Identity and access management

## Requirements

* [Terraform](https://www.terraform.io/intro/getting-started/install.html)
* [Terragrunt](https://github.com/gruntwork-io/terragrunt#install-terragrunt)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [helm](https://helm.sh/)
* [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)

## Documentation

User guides, feature documentation and examples are available [here](https://clusterfrak-dynamics.github.io/teks/)

## About Kiam

Kiam prevents pods from accessing EC2 instances IAM role and therefore using the instances role to perform actions on AWS. It also allows pods to assume specific IAM roles if needed. To do so `kiam-agent` acts as an iptables proxy on nodes. It intercepts requests made to EC2 metadata and redirect them to a `kiam-server` that fetches IAM credentials and pass them to pods.

Kiam is running with an IAM user and use a secret key and a access key (AK/SK).

### Addons that require specific IAM permissions

Some addons interface with AWS API, for example:

* `cluster-autoscaler`
* `external-dns`
* `cert-manager`
* `virtual-kubelet`
* `cni-metric-helper`

## License

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fclusterfrak-dynamics%2Fteks.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fclusterfrak-dynamics%2Fteks?ref=badge_large)
