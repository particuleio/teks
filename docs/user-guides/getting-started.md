# Getting started

## Tooling requirements

The necessary tools are in `requirements.yaml` you can install them any way you want, make sure they are available in your $PATH.

The following dependencies are required on the deployer host:

* [Terraform](https://www.terraform.io/intro/getting-started/install.html)
* [Terragrunt](https://github.com/gruntwork-io/terragrunt#install-terragrunt)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [helm](https://helm.sh/)
* [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)

## AWS requirements

* At least one AWS account
* `awscli` configured ([see installation instructions](https://aws.amazon.com/cli/)) to access your AWS account.
* A route53 hosted zone if you plan to use `external-dns` or `cert-manager` but it is not a hard requirement.

## Getting the template repository

You can either clone the repo locally or generate/fork a template from github.

```bash
git clone https://github.com/clusterfrak-dynamics/teks.git --branch v6.0.0
```

The terraform directory structure is the following:

```bash
.
└── live
    └── demo
        ├── common_tags.yaml
        ├── common_values.yaml
        ├── eu-west-3
        │   ├── ecr
        │   │   ├── provider.tf
        │   │   └── terragrunt.hcl
        │   ├── eks
        │   │   ├── kubeconfig
        │   │   ├── manifests
        │   │   │   ├── calico.yaml
        │   │   │   ├── psp-default-clusterrole.yaml
        │   │   │   ├── psp-default-clusterrolebinding.yaml
        │   │   │   ├── psp-default.yaml
        │   │   │   ├── psp-privileged-clusterrole.yaml
        │   │   │   ├── psp-privileged-clusterrolebinding.yaml
        │   │   │   ├── psp-privileged-node-rolebinding.yaml
        │   │   │   └── psp-privileged.yaml
        │   │   ├── manifests.tf
        │   │   ├── providers.tf
        │   │   └── terragrunt.hcl
        │   ├── eks-addons
        │   │   ├── examples
        │   │   │   ├── keycloak-values.yaml
        │   │   │   └── kong-values.yaml
        │   │   ├── providers.tf
        │   │   └── terragrunt.hcl
        │   ├── eks-namespaces
        │   │   ├── providers.tf
        │   │   └── terragrunt.hcl
        │   └── vpc
        │       ├── provider.tf
        │       └── terragrunt.hcl
        └── terragrunt.hcl
```

Each cluster in inside the `terraform/live` folder and then modules are group by AWS region.

## Start a new cluster

Create a new cluster beside `demo`:

```bash
cp -ar demo mycluster
```

## Configuring Terragrunt remote state

`live/demo/terragrunt.hcl` is the parent terragrunt file use to configure remote state.

The configuration is done automatically from the `common_values.yaml` file.

```yaml
{!terraform/live/demo/common_values.yaml!}
```

The values here will generate automatically the parent terragrunt file.

```json
{!terraform/live/demo/terragrunt.hcl!}
```

You can either customize the values or edit directly the `terragrunt.hcl` file.

## Running Terragrunt command

Terragrunt command are run inside their respective folder, for example, to run the `vpc` module:

```bash
cd vpc
terragrunt apply
```
