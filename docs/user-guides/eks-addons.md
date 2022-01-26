# EKS addons module

`terraform-kubernetes-addons:aws` is a custom module maintained
[here][terraform-kubernetes-addons:aws] and provides:

[terraform-kubernetes-addons:aws]: https://github.com/particuleio/terraform-kubernetes-addons/tree/main/modules/aws

* helm v3 charts
* manifests
* operators

For commonly used addons one Kubernetes and most specifically with EKS.

The configuration is curated to be tightly integrated with AWS and EKS.

## Customization

All the configuration is done in `eks-addons/terragrunt.hcl`.

```json
{!terragrunt/live/production/eu-west-1/clusters/demo/eks-addons/terragrunt.hcl!}
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
