# tEKS

<p align="center">
  <img src="images/logo.png">
</p>

![terragrunt:env:demo](https://github.com/particuleio/teks/workflows/terragrunt:env:demo/badge.svg)
![teks:mkdocs](https://github.com/particuleio/teks/workflows/teks:mkdocs/badge.svg)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fparticuleio%2Fteks.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fparticuleio%2Fteks?ref=badge_shield)

tEKS is a set of Terraform / Terragrunt modules designed to get you everything you need to run a production EKS cluster on AWS. It ships with sensible defaults, and add a lot of common addons with their configurations that work out of the box.

:warning: the v5 and further version of this project have been completely revamp and now offer a skeleton to use as a base for your infrastructure projects around EKS. All the modules have been moved outside this repository and get their own versioning. The [old README is accessible here](https://github.com/particuleio/teks/tree/release-4.X)

## Terraform/Terragrunt

* Terraform implementation is available in the [`terraform`](./terraform) folder.
* Terragrunt implementation is available in the [`terragrunt`](./terragrunt) folder.

## Requirements

### Terraform

* [Terraform](https://www.terraform.io/downloads.html)
* [direnv](https://direnv.net/): available in every Linux distribution
* [tfenv](https://github.com/cloudposse/tfenv)

### Terragrunt

* [Terraform](https://www.terraform.io/downloads.html)
* [Terragrunt](https://github.com/gruntwork-io/terragrunt/releases)

## Main purposes

The main goal of this project is to glue together commonly used tooling with Kubernetes/EKS and to get from an AWS Account to a production cluster with everything you need without any manual configuration.

## What you get

A production cluster all defined in IaaC with Terraform/Terragrunt:

* AWS VPC if needed based on [`terraform-aws-vpc`](https://github.com/terraform-aws-modules/terraform-aws-vpc)
* EKS cluster base on [`terraform-aws-eks`](https://github.com/terraform-aws-modules/terraform-aws-eks)
* Kubernetes addons based on [`terraform-kubernetes-addons`](https://github.com/particuleio/terraform-kubernetes-addons): provides various addons that are often used on Kubernetes and specifically on EKS.
* Kubernetes namespaces quota management based on [`terraform-kubernetes-namespaces`](https://github.com/particuleio/terraform-kubernetes-addons): allows administrator to manage namespaces and quotas from a centralized configuration with Terraform.

Everything is tied together with Terragrunt and allows you to deploy a multi cluster architecture in a matter of minutes (ok maybe an hour) and different AWS accounts for different environments.

## Curated Features

The main additionals features are the curated addons list, see [here](https://github.com/particuleio/terraform-kubernetes-addons) and in the customization of the cluster policy

### Enforced security

* Default PSP is removed and sensible defaults are enforced
* All addons have specific PSP enabled
* No IAM credentials on instances, everything is enforced with [IRSA](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/) or [KIAM](https://github.com/uswitch/kiam)
* Each addons is deployed in it's own namespace with sensible default network policies

### Out of the box monitoring

* Prometheus Operator with defaults dashboards
* Addons that support metrics are enable along with their `serviceMonitor`
* Custom grafana dashboard are available by default.

### Helm v3 provider

* All addons support Helm v3 configuration
* All charts are easily customizable

### Other and not limited to

* priorityClasses for addons
* use of [`kubectl-provider`], no more local exec and custom manifest are properly handled
* lot of manual stuff have been automated under the hood

## Requirements

Terragrunt is not a hard requirement but all the modules are tested with Terragrunt.

* [Terraform](https://www.terraform.io/intro/getting-started/install.html)
* [Terragrunt](https://github.com/gruntwork-io/terragrunt#install-terragrunt)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [helm](https://helm.sh/)
* [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)

## Examples

[`terraform/live`](terraform/live) folder provides an opinionated directory structure for a production environment with an example using

## Additional infrastructure blocks

If you wish to extend your infrastructure you can pick up additional modules on the [particuleio github page](https://github.com/particuleio).
Some modules can also be found on the [clusterfrak-dynamics github page](https://github.com/clusterfrak-dynamics).

## Branches

* [`main`](https://github.com/particuleio/teks/tree/main): Backward incompatible with v1.X but compatible with v2.X, releases bumped to v3.X because a lot has changed.
* [`release-1.X`](https://github.com/particuleio/teks/tree/release-1.X): Compatible with Terraform < 0.12 and Terragrunt < 0.19. Be sure to target the same modules version.
* [`release-2.X`](https://github.com/particuleio/teks/tree/release-2.X): Compatible with Terraform >= 0.12 and Terragrunt >= 0.19. Be sure to target the same modules version.

## License

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fparticuleio%2Fteks.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fparticuleio%2Fteks?ref=badge_large)
