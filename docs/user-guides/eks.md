# EKS module

## Upstream configuration

EKS module is also [upstream](https://github.com/terraform-aws-modules/terraform-aws-eks) and allow to deploy an EKS cluster which supports:

* managed node pools
* launch configuration node pools
* launch template node pools

tEKS uses launch template by default and use one node pool per availability zone.

You can use any inputs from the upstream module to configure the cluster in `eks/terragrunt.hcl`.

```json
{!terraform/live/demo/eu-west-3/eks/terragrunt.hcl!}
```

## Customizations

Besides the upstream module, there are some customizations. If you look at the directory structure:

```bash
.
├── manifests
│   ├── calico.yaml
│   ├── psp-default-clusterrole.yaml
│   ├── psp-default-clusterrolebinding.yaml
│   ├── psp-default.yaml
│   ├── psp-privileged-clusterrole.yaml
│   ├── psp-privileged-clusterrolebinding.yaml
│   ├── psp-privileged-node-rolebinding.yaml
│   └── psp-privileged.yaml
├── manifests.tf
├── providers.tf
└── terragrunt.hcl
```

### Terragrunt hooks

In addition to the upstream module there is some `hooks` included, these `hooks` can be remove if necessary. In order:

* Download the `terraform-provider-kubectl` to manage manifests (necessary if using `manifests.tf)
* Copy the kubeconfig locally
* Label the `kube-system` namespace with its name
* Remove the defaults EKS podSecurityPolicies (see [#401](https://github.com/aws/containers-roadmap/issues/401))

### Custom manifests

`terraform-provider-kubectl` allows to deploy Kubernetes manifests in a cleaner way than using a `local-exec`. `manifests.tf` is parsing the manifest folder and applying them to the cluster.

#### Calico

Calico is used to enable network policies enforcement on the cluster. To disable calico you can remove the `calico.yaml` file.

#### Pod Security Policies

The default EKS [Pod Security Policies](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) is privileged. By default it is removed (by the previous hooks) and more sensible non privileged default pod security policies are deployed:

* all the service account in `kube-system` can use `privileged`

```yaml
{!terraform/live/demo/eu-west-3/eks/manifests/psp-privileged.yaml!}
```

* any other authenticated user can use `default`

```yaml
{!terraform/live/demo/eu-west-3/eks/manifests/psp-default.yaml!}
```


The input variable `psp_privileged_ns` allow to give privileged to services account inside a namespace. Eg. in `terragrunt.hcl`:

```json
  psp_privileged_ns = [
    "cluster-autoscaler", #waiting for https://github.com/helm/charts/pull/20891
    "istio-system" #istio does not support psp by default
  ]
```

This gives to all the service accounts inside `cluster-autoscaler` and `istio-system` access to the `privileged` pod security policy.



##