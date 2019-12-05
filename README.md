# tEKS

[![Build Status](https://travis-ci.com/clusterfrak-dynamics/teks.svg?branch=master)](https://travis-ci.com/clusterfrak-dynamics/teks)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fclusterfrak-dynamics%2Fteks.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fclusterfrak-dynamics%2Fteks?ref=badge_shield)

tEKS is a set of Terraform / Terragrunt modules designed to get you everything you need to run a production EKS cluster on AWS. It ships with sensible defaults, and add a lot of common addons with their configurations that work out of the box.

:warning: the v5 of this project has been completely revamp and now offer a skeleton to use as a base for your infrastructure projects around EKS. All the modules have been moved outside this repository and get their own versioning. The [old README is accessible here](https://github.com/clusterfrak-dynamics/teks/tree/release-4.X)

## Modules

* [`terraform-aws-vpc`](https://github.com/terraform-aws-modules/terraform-aws-vpc)
* [`terraform-aws-eks`](https://github.com/terraform-aws-modules/terraform-aws-eks)
* [`terraform-kubernetes-addons`](https://github.com/clusterfrak-dynamics/terraform-kubernetes-addons): provides various addons that are often used on Kubernetes and specifically on EKS.
* [`terraform-kubernetes-namespaces`](https://github.com/clusterfrak-dynamics/terraform-kubernetes-addons): allows administrator to manage namespaces and quotas from a centralized configuration with Terraform.

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

If you wish to extend your infrastructure you can pick up additional modules on the [clusterfrak-dynamics github page](https://github.com/clusterfrak-dynamics)

## Branches

* [`master`](https://github.com/clusterfrak-dynamics/teks/tree/master): Backward incompatible with v1.X but compatible with v2.X, releases bumped to v3.X because a lot has changed.
* [`release-1.X`](https://github.com/clusterfrak-dynamics/teks/tree/release-1.X): Compatible with Terraform < 0.12 and Terragrunt < 0.19. Be sure to target the same modules version.
* [`release-2.X`](https://github.com/clusterfrak-dynamics/teks/tree/release-2.X): Compatible with Terraform >= 0.12 and Terragrunt >= 0.19. Be sure to target the same modules version.

## License

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fclusterfrak-dynamics%2Fteks.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fclusterfrak-dynamics%2Fteks?ref=badge_large)
