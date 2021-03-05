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
git clone https://github.com/particuleio/teks.git
```

The terraform directory structure is the following:

```bash
.
└── live
    ├── backend
    │   ├── backend.tf
    │   ├── providers.tf
    │   └── state.tf
    ├── demo
    │   ├── env_tags.yaml
    │   └── eu-west-3
    │       ├── clusters
    │       │   └── full
    │       │       ├── eks
    │       │       │   ├── aws-provider.tf -> ../../../../../shared/aws-provider.tf
    │       │       │   ├── backend.tf -> ../../../../../backend/backend.tf
    │       │       │   ├── data.tf
    │       │       │   ├── locals.tf -> ../../../../../shared/locals.tf
    │       │       │   └── main.tf
    │       │       ├── eks-addons
    │       │       │   ├── aws-provider.tf -> ../../../../../shared/aws-provider.tf
    │       │       │   ├── backend.tf -> ../../../../../backend/backend.tf
    │       │       │   ├── data.tf
    │       │       │   ├── locals.tf -> ../../../../../shared/locals.tf
    │       │       │   ├── main.tf
    │       │       │   └── versions.tf
    │       │       └── vpc
    │       │           ├── aws-provider.tf -> ../../../../../shared/aws-provider.tf
    │       │           ├── backend.tf -> ../../../../../backend/backend.tf
    │       │           ├── locals.tf -> ../../../../../shared/locals.tf
    │       │           └── main.tf
    │       └── region_values.yaml
    ├── global_tags.yaml
    ├── global_values.yaml
    └── shared
        ├── aws-provider.tf
        └── locals.tf
```

Each cluster in inside the `terraform/live` folder and then modules are grouped
by AWS region.

## Start a new cluster

Create a new cluster beside `demo`:

```bash
cp -ar demo mycluster
```

## Configuring the remote state

Configuration of the remote state is based on the value of the
`global_values.yaml` file in the `terraform` and the `terragrunt` directories
based on the installation method you used.

Both files are following the same structure.

```yaml
{!terragrunt/live/global_values.yaml!}
```

Adapt these values to match your configuration (`prefix`, 'project').

Based on the configuration, both methods will create the following resources:

* S3 bucket named `{prefix}-{project}-{tf|tg}-state`: store the state
* DynamoDB table named `{prefix}-{project}-{tf|tg}-state-lock`: prevent
concurrent use

The resource names will include information based on the configuration method
used. Using `terraform` will create resources with `tf` in their name, and `tg`
when using `terragrunt`.

Using the current values, the resources created to use `terraform`
will be:

* S3: `pio-teks-tf-state`
* DynamoDB: `pio-state-tf-state-lock`

### Remote state for Terraform

If you plan on using terraform to setup `teks`, you need to create your
remote backend using [cloudposse/terraform-aws-tfstate-backend][tf-aws-tfstate-backend]
configured in `terraform/live/backend/state.tf`.

In order to configure the S3 backend for terraform, configure your `global_values.yaml`
then go in the `terraform/live/backend` directory.

* `terraform init` init the terraform module.
* `terraform apply -auto-approve` to create the S3 backend.
* `terraform init -force-copy` will copy the local backend to the S3 backend.

The `terraform-aws-tfstate-backend` module will create or update the
`terraform/live/backend/backend.tf` file, which is symlinked to the child
modules (`vpc`, `eks`, `eks-addons`).

```json
{!terraform/live/backend/backend.tf!}
```

Further documentation regarding the remote backend configuration
can be found at [terraform-aws-tfstate-backend#create][tf-aws-tfstate-backend#create].

[tf-aws-tfstate-backend]: https://github.com/cloudposse/terraform-aws-tfstate-backend
[tf-aws-tfstate-backend#create]: https://github.com/cloudposse/terraform-aws-tfstate-backend#create

### Remote state for Terragrunt

`terragrunt/live/demo/terragrunt.hcl` is the parent terragrunt file use
to configure remote state.

The configuration is done automatically based on the
`terragrunt/live/global_values.yaml` file.

The values here will generate automatically the parent terragrunt file.

```json
{!terragrunt/live/terragrunt.hcl!}
```

You can either customize the values or edit directly the `terragrunt.hcl` file.

## Running Terragrunt command

Terragrunt command are run inside their respective folder, for example, to run the `vpc` module:

```bash
cd vpc
terragrunt apply
```
