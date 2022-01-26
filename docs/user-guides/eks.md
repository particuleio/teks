 EKS module

## Upstream configuration

EKS module is also [upstream](https://github.com/terraform-aws-modules/terraform-aws-eks) and allow to deploy an EKS cluster which supports:

* managed node pools
* self managed node groups using launch template

tEKS uses EKS managed node groups by default and use one node pool per availability zone.

You can use any inputs from the upstream module to configure the cluster in `eks/terragrunt.hcl`.

See all available feature [here](https://github.com/terraform-aws-modules/terraform-aws-eks#available-features)

```json
{!terragrunt/live/production/eu-west-1/clusters/demo/eks/terragrunt.hcl!}
```
