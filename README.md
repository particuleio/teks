# tEKS

[![Build Status](https://travis-ci.com/clusterfrak-dynamics/teks.svg?branch=master)](https://travis-ci.com/clusterfrak-dynamics/teks)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fclusterfrak-dynamics%2Fteks.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fclusterfrak-dynamics%2Fteks?ref=badge_shield)

tEKS is a set of Terraform / Terragrunt modules designed to get you everything you need to run a production EKS cluster on AWS. It ships with sensible defaults, and add a lot of common addons with their configurations that work out of the box.

:warning: NOT YET COMPATIBLE WITH TERRAGRUNT 0.19.X AND TERRAFORM 0.12.X

## Branches

* [`master`](https://github.com/clusterfrak-dynamics/teks/tree/master): Backward incompatible, development will continue with Terraform 0.12.X and Terragrunt 0.19.X. Releases bumped to v2.X.X
* [`release-1.X`](https://github.com/clusterfrak-dynamics/teks/tree/release-1.X): Compatible with Terraform < 0.12 and Terragrunt < 0.19. Be sure to target the same modules version.

## Main features

* Node pools with customizable labels / taints
* Fully customizable kubelet args
* Supports new or existing VPC
* Calico for network policies
* Common addons with associated IAM permissions if needed:
  * [cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler): scale worker nodes based on workload
  * [external-dns](https://github.com/kubernetes-incubator/external-dns): sync ingress and service records in route53
  * [cert-manager](https://github.com/jetstack/cert-manager): automatically generate TLS certificates, supports ACME v2
  * [kiam](https://github.com/uswitch/kiam): prevents pods to access EC2 metadata and enables pods to assume specific AWS IAM roles
  * [nginx-ingress](https://github.com/kubernetes/ingress-nginx): processes *Ingress* object and acts as a HTTP/HTTPS proxy (compatible with cert-manager)
  * [metrics-server](https://github.com/kubernetes-incubator/metrics-server): enable metrics API and horizontal pod scaling (HPA)
  * [prometheus-operator](https://github.com/coreos/prometheus-operator): Monitoring / Alerting / Dashboards
  * [virtual-kubelet](https://github.com/coreos/prometheus-operator): enables using ECS Fargate as a provider to run workload without EC2 instances
  * [fluentd-cloudwatch](https://github.com/helm/charts/tree/master/incubator/fluentd-cloudwatch): forwards logs to AWS Cloudwatch
  * [node-problem-detector](https://github.com/kubernetes/node-problem-detector): Forwards node problems to Kubernetes events
  * [flux](https://github.com/weaveworks/flux): Continous Delivery with Gitops workflow.
  * [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets): Technology agnostic, store secrets on git.

## Requirements

* [Terraform 0.11.X](https://www.terraform.io/intro/getting-started/install.html)
* [Terragrunt 0.18.X](https://github.com/gruntwork-io/terragrunt#install-terragrunt)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [helm](https://helm.sh/)
* [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)

## Documentation

User guides, feature documentation and examples are available [here](https://clusterfrak-dynamics.github.io/teks/)

## About Kiam

Kiam prevents pods from accessing EC2 instances IAM role and therefore using the instances role to perform actions on AWS. It also allows pods to assume specific IAM roles if needed. To do so `kiam-agent` acts as an iptables proxy on nodes. It intercepts requests made to EC2 metadata and redirect them to a `kiam-server` that fetches IAM credentials and pass them to pods.

For security reasons, because Kiam needs to assume an IAM role that can assume other roles, it is best to run it on a dedicated node with specific IAM permission where no other workload are running and where there is no `kiam-agent` (because kiam-server need access to EC2 metadata). This is taken care of by default but it is customizable.

### Addons that require specific IAM permissions

Some addons interface with AWS API, for example:

* `cluster-autoscaler`
* `external-dns`
* `cert-manager`
* `virtual-kubelet`: only with Kiam enable

#### Without KIAM

If you are not using Kiam, addons must access EC2 instances metdata to get credentials and access Kubernetes API, it is best for security reason to use a dedicated node for addons in that case to avoid other pods to access IAM roles and messed up route53, or scale down your cluster for example.

#### With Kiam

If you are using Kiam, these addons can run either with instances IAM roles on the same dedicated nodes where `kiam-server` is running amd bypass `kiam-agent` or they can run anywhere and assume a specific role through Kiam.

The following matrix tries to explain the possible combinations:

<table>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td>virtual-kubelet<br>(assume role with Kiam)</td>
    <td></td>
  </tr>
  <tr>
    <td>cluster-autoscaler</td>
    <td></td>
    <td>cluster-autoscaler</td>
    <td></td>
    <td></td>
    <td>cert-manager<br>(assume role with Kiam)</td>
    <td>cert-manager<br>(assume role with Kiam)</td>
  </tr>
  <tr>
    <td>external-dns</td>
    <td></td>
    <td>external-dns</td>
    <td></td>
    <td></td>
    <td>cluster-autoscaler<br>(assume role with Kiam)</td>
    <td>cluster-autoscaler<br>(assume role with Kiam)</td>
  </tr>
  <tr>
    <td>cert-manager</td>
    <td></td>
    <td>cert-manager</td>
    <td>virtual-kubelet<br>(assume role with Kiam)</td>
    <td></td>
    <td>external-dns<br>(assume role with Kiam)</td>
    <td>external-dns<br>(assume role with Kiam)</td>
  </tr>
  <tr>
    <td>kiam-server</td>
    <td></td>
    <td>kiam-server</td>
    <td>kiam-agent</td>
    <td>kiam-server</td>
    <td>kiam-agent</td>
    <td>kiam-agent<br>(in HostNetwork, bypass kiam-agent)<br></td>
  </tr>
  <tr>
    <td>Dedicated node(s)<br>with IAM roles attached</td>
    <td>Worker node(s)</td>
    <td>Dedicated node(s) with IAM roles attached<br>(bypass kiam-agent)</td>
    <td>Worker node(s)</td>
    <td>Dedicated node(s) with only IAM role for Kiam<br>(bypass kiam-agent)</td>
    <td>Worker node(s)</td>
    <td>Worker node(s) with only IAM role for Kiam<br>(bypass kiam-agent)<br>!!! Security concerns !!!</td>
  </tr>
  <tr>
    <td colspan="2">Without Kiam</td>
    <td colspan="2">With Kiam</td>
    <td colspan="2">With Kiam</td>
    <td>With Kiam</td>
  </tr>
</table>

## License

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fclusterfrak-dynamics%2Fteks.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fclusterfrak-dynamics%2Fteks?ref=badge_large)
