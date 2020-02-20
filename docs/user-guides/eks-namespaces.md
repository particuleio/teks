# EKS namespaces module

`eks-namespace` is a custom module maintained [here](https://github.com/clusterfrak-dynamics/terraform-kubernetes-namespaces) and allow to create and manage Kubernetes namespaces with Terragrunt/Terraform.

It provides:

* Namespaces [quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
* Namesapces [limitranges](https://kubernetes.io/docs/concepts/policy/limit-range/)

## Customization

Just like the other modules, custom configuration is done in `terragrunt.hcl`. It takes a list of namespaces with their configuration as an input variable.

```json
{!terraform/live/demo/eu-west-3/eks-namespaces/terragrunt.hcl!}
```
