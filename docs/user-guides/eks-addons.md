# EKS addons module

`terraform-kubernetes-addons:aws` is a custom module maintained
[here][terraform-kubernetes-addons:aws] and provides:

[terraform-kubernetes-addons:aws]: https://github.com/particuleio/terraform-kubernetes-addons/tree/main/modules/aws

* helm v3 charts
* manifests
* operators

For commonly used addons one Kubernetes and most specifically with EKS.
The deployments are curated to be tightly integrated with AWS and EKS.

The following addons are available and work out of the box.

## Helm charts

All charts have been tested with Helm v3 and the `terraform-provider-helm` v1.0 which supports Helm v3. They can be easily customize with custom values.

* [cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler): scale worker nodes based on workload.
* [external-dns](https://github.com/kubernetes-incubator/external-dns): sync ingress and service records in route53.
* [cert-manager](https://github.com/jetstack/cert-manager): automatically generate TLS certificates, supports ACME v2.
* [nginx-ingress](https://github.com/kubernetes/ingress-nginx): processes *Ingress* object and acts as a HTTP/HTTPS proxy (compatible with cert-manager).
* [metrics-server](https://github.com/kubernetes-incubator/metrics-server): enable metrics API and horizontal pod scaling (HPA).
* [prometheus-operator](https://github.com/coreos/prometheus-operator): Monitoring / Alerting / Dashboards.
* [fluentd-cloudwatch](https://github.com/helm/charts/tree/master/incubator/fluentd-cloudwatch): forwards logs to AWS Cloudwatch.
* [node-problem-detector](https://github.com/kubernetes/node-problem-detector): Forwards node problems to Kubernetes events
* [flux](https://github.com/weaveworks/flux): Continuous Delivery with Gitops workflow.
* [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets): Technology agnostic, store secrets on git.
* [kong](https://konghq.com/kong): API Gateway ingress controller.
* [keycloak](https://www.keycloak.org/) : Identity and access management

## Kubernetes Manifests

Kubernetes manifests are deployed with [`terraform-provider-kubectl`](https://github.com/gavinbunney/terraform-provider-kubectl)

* [cni-metrics-helper](https://docs.aws.amazon.com/eks/latest/userguide/cni-metrics-helper.html): Provides cloudwatch metrics for VPC CNI plugins.

## Operator

Some project are transitioning to [Operators](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/). Istio is going to drop Helm support and is not compatible with Helm v3 so it has been removed and replaced with the [Istio operator](https://istio.io/blog/2019/introducing-istio-operator/)

* [istio-operator](https://istio.io): Service mesh for Kubernetes.

## IAM permissions

Some addons require specific IAM permission. This can be done by either:

* IRSA: [IAM role for service account](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/) which is the default and recommended way

Addons that need IAM access have two variables:

* `create_resources_irsa`: default to true and uses IAM role for service account

There is no specific config, everything is taken care of by the module.

## Customization

All the configuration is done in `eks-addons/terragrunt.hcl`.

```json
{!terragrunt/live/demo/eu-west-3/clusters/full/eks-addons/terragrunt.hcl!}
```

### Default charts values

Some values are defined by default directly into the module. These can off
course be overridden and or merged/replaced. You can find the defaults values
in the [upstream module][terraform-kubernetes-addons:aws]. Eg. default values
for `cluster-autoscaler` are in [`cluster-autoscaler.tf`](https://github.com/particuleio/terraform-kubernetes-addons/blob/main/modules/aws/cluster-autoscaler.tf).

### Overriding Helm provider values

Helm provider have defaults values defined [here](https://github.com/particuleio/terraform-kubernetes-addons/blob/main/locals.tf):

```json
  helm_defaults_defaults = {
    atomic                = false
    cleanup_on_fail       = false
    dependency_update     = false
    disable_crd_hooks     = false
    disable_webhooks      = false
    force_update          = false
    recreate_pods         = false
    render_subchart_notes = true
    replace               = false
    reset_values          = false
    reuse_values          = false
    skip_crds             = false
    timeout               = 3600
    verify                = false
    wait                  = true
    extra_values          = ""
  }
```

These can be overridden globally with the `helm_defaults` input variable or
can be overridden per chart in `terragrunt.hcl`:

```json
  helm_defaults = {
    replace = true
    verify  = true
    timeout = 300
  }


  cluster_autoscaler = {
    create_iam_resources_irsa = true
    iam_policy_override       = ""
    version                   = "v1.14.7"
    chart_version             = "6.4.0"
    enabled                   = true
    default_network_policy    = true
    cluster_name              = dependency.eks.outputs.cluster_id
    timeout                   = 3600 <= here you can add any helm provider override
  }
```

### Overriding charts values.yaml

It is possible to add or override values per charts. Helm provider use the
same merge logic as Helm so you can basically rewrite the whole
`values.yaml` if needed.

Each chart has a `extra_values` variable where you can specify custom values.

```json
flux = {
    create_iam_resources_irsa = true
    version                   = "1.18.0"
    chart_version             = "1.2.0"
    enabled                   = false
    default_network_policy    = true

    extra_values = <<EXTRA_VALUES
git:
  url: "ssh://git@gitlab.com/myrepo/gitops-${local.env}.git"
  pollInterval: "2m"
rbac:
  create: false
registry:
  automationInterval: "2m"
EXTRA_VALUES
}
```

There are some examples in the `terragrunt.hcl` file. Not all the variables
available are present. If you want a full list of variable, you can find them
in the [upstream module][terraform-kubernetes-addons:aws]. For example
for `cluster-autoscaler` you can see the default [here](https://github.com/particuleio/terraform-kubernetes-addons/blob/main/modules/aws/cluster-autoscaler.tf#L2).
