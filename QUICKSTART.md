# Quickstart

## Cloud Requirements

* At least one AWS Account with `AdministratorAccess`
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with the account you want to deploy into
* An [AWS route53](https://aws.amazon.com/route53/) domain name if you want default Ingresses to just work.
    box. It is fine without it but External DNS and Cert Manager won't work out
    of the box

### Dependencies

Dependencies can be found in
[`.tools-version`](https://github.com/particuleio/teks/blob/main/.tool-versions)
this file is compatible with [asdf](https://asdf-vm.com/) which is not a hard
requirement but our way of managing required tooling.

### Enabling plugins

```
for p in $(cut -d " " .tool-versions -f1); do asdf plugin add $p; done
```

### Installing tools

```
asdf install
```

## Create repository structure

1. [Clone the template on Github](https://github.com/particuleio/teks/generate)

2. In `./terragrunt/live/global_values` adapt to your requirements

```
---
# Your AWS Account ID
aws_account_id: 161285725140

# Prefix to be added to created resources
prefix: pio-teks

# AWS S3 bucket region where Terraform will store state
tf_state_bucket_region: eu-west-1

# Github username or organization, this can be used by Flux2 to auto configure
# Github bootstrap
github_owner: particuleio
```

3. In `./terragrunt/live/production/env_values.yaml` adapt to your requirements,
   it is also possible to override variables defined in `global_values.yaml`
   here, for example when using different AWS account per environment. Here we
   will use only one AWS account and deploy the production environment.

```
---
# Environment name, normally equal to folder name, here it is production by default
env: production

# Default domain name that will be used by default ingress resources, use a registered Route53 domain in the AWS Account
default_domain_name: clusterfrak-dynamics.io
```

4. In `terragrunt/live/production/eu-west-1/region_values.yaml` there is nothing
   to change if you want to use the example region (`eu-west-1`), if you want to
   use another region, just rename the folder, for example `us-east-1` and then
   edit `region_values.yaml` to suit your need.

```
---
aws_region: eu-west-1
```

5. In
   `terragrunt/live/production/eu-west-1/clusters/demo/component_values.yaml`,
   `name` will be used to compute full cluster name, the default is
   `$PREFIX-$ENV_$NAME` which is defined
   [here](https://github.com/particuleio/teks/blob/main/terragrunt/live/production/terragrunt.hcl#L34).
   It is of course possible to override default variable inside the respective
   `terragrunt.hcl` files

6. You can edit each modules individually inside
   `terragrunt/live/production/eu-west-1/clusters/demo`.
   For official modules, please refer to their respective documentations. For
   `eks-addons` you can check the module [here](https://github.com/particuleio/terraform-kubernetes-addons).

7. Configure Flux2 Gitops in
   `terragrunt/live/production/eu-west-1/clusters/demo/eks-addons/terragrunt.hcl` or disable it if needed, you will need a
   GITHUB_TOKEN available from you terminal. Also to configure it according the
   your repository name.

```
  # For this to work:
  # * GITHUB_TOKEN should be set
  flux2 = {
    enabled               = true
    target_path           = "gitops/clusters/${include.root.locals.merged.env}/${include.root.locals.merged.name}"
    github_url            = "ssh://git@github.com/${include.root.locals.merged.github_owner}/teks"
    repository            = "teks"
    branch                = "main"
    repository_visibility = "public"
    version               = "v0.25.3"
    auto_image_update     = true
  }

```

6. Make sure you AWS credential are correctly loaded inside your terminal, then
   from the `terragrunt/live/production/eu-west-1/clusters/demo`.

```
terragrunt run-all apply


INFO[0000] The stack at /home/klefevre/git/archifleks/teks-quickstart/terragrunt/live/production/eu-west-1/clusters/demo will be processed in the following order for command apply:
Group 1
- Module /home/klefevre/git/archifleks/teks-quickstart/terragrunt/live/production/eu-west-1/clusters/demo/encryption-config
- Module /home/klefevre/git/archifleks/teks-quickstart/terragrunt/live/production/eu-west-1/clusters/demo/vpc

Group 2
- Module /home/klefevre/git/archifleks/teks-quickstart/terragrunt/live/production/eu-west-1/clusters/demo/eks
- Module /home/klefevre/git/archifleks/teks-quickstart/terragrunt/live/production/eu-west-1/clusters/demo/vpc-endpoints

Group 3
- Module /home/klefevre/git/archifleks/teks-quickstart/terragrunt/live/production/eu-west-1/clusters/demo/aws-auth
- Module /home/klefevre/git/archifleks/teks-quickstart/terragrunt/live/production/eu-west-1/clusters/demo/eks-addons-critical

Group 4
- Module /home/klefevre/git/archifleks/teks-quickstart/terragrunt/live/production/eu-west-1/clusters/demo/eks-addons
```

7. Load Kubeconfig, you still need to have the AWS CLI loaded and configure with
   the right account

```
export KUBECONFIG=$PWD/eks/kubeconfig
```

8. Check out ingress objects

```
k get ingress --all-namespaces
NAMESPACE    NAME                            CLASS   HOSTS                               ADDRESS                                                                         PORTS     AGE
monitoring   kube-prometheus-stack-grafana   nginx   telemetry.clusterfrak-dynamics.io   k8s-ingressn-ingressn-d192ac60af-c080dd921f212013.elb.eu-west-1.amazonaws.com   80, 443   12m
```

9. Log into Grafana. From the `eks-addons` folder

```
terragrunt output grafana_password
"PASSWORD"
```

10. Use the cluster to do stuff you normally do on a Kubernetes Cluster

11. To destroy everything simply run `terragrunt run-all destroy --terragrunt-exclude-dir=aws-auth` from the
    `eu-west-1/clusters/demo` folder.

:warning: there is an issue with flux 2 namespace not terminating correctly
because CRDs are deleted before namespace is terminated. To unstuck `flux-system` namespace deletion, you can run the following command:

```
kubectl get namespace "flux-system" -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" | kubectl replace --raw /api/v1/namespaces/flux-system/finalize -f -
```

12. Verify everything is deleted on AWS console (I just did not want the
    quickstart to end on an odd number)
