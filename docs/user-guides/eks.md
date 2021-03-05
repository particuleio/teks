# EKS module

## Upstream configuration

EKS module is also [upstream](https://github.com/terraform-aws-modules/terraform-aws-eks) and allow to deploy an EKS cluster which supports:

* managed node pools
* launch configuration node pools
* launch template node pools

tEKS uses launch template by default and use one node pool per availability zone.

You can use any inputs from the upstream module to configure the cluster in `eks/terragrunt.hcl`.

```json
{!terragrunt/live/demo/eu-west-3/clusters/full/eks/terragrunt.hcl!}
```
