# Deploying tEKS minimal version

This guide explains how to deploy a minimal version of tEKS that's basically a bare EKS cluster.

## Prepping environment

### Terragrunt environment

In `terraform/live` folder, copy the `sample` environment to a new folder, we will use `minimal` across this guide:

```bash
cp -ar sample minimal
tree
.
├── minimal
│   ├── eks
│   │   └── terraform.tfvars
│   └── eks-addons
│       └── terraform.tfvars
├── sample
│   ├── eks
│   │   └── terraform.tfvars
│   └── eks-addons
│       └── terraform.tfvars
└── terraform.tfvars

6 directories, 5 files
```

### Terragrunt remote state

Edit `live/terraform.tfvars`:

```tf
{!terraform/live/terraform.tfvars!}
```

Change bucket and dynamodb to suit your environment, Terragrunt can create the bucket and dynamodb table if they do not exist.

### EKS module variables

Edit `live/minimal/eks/terraform.tfvars`:

This module setup infrastructure components and everything related to AWS, such as IAM permission if necessary.

```json
{!terraform/live/minimal/eks/terraform.tfvars!}
```

Everything should already be turned off by default. You should just have to edit `cluster-name` and the `aws["region"]` variable. 

You also need to customize the node pool at the end of the file to suit your needs. You need to, at least, change the SSH Key for one available in S3.

```json
node-pools = [
  {
    name = "controller"
    min_size = 1
    max_size = 1
    desired_capacity = 1
    instance_type = "t3.medium"
    key_name = "klefevre-sorrow"
    volume_size = 30
    volume_type = "gp2"
    autoscaling = "disabled"
    kubelet_extra_args = "--kubelet-extra-args '--node-labels node-role.kubernetes.io/controller=\"\" --register-with-taints node-role.kubernetes.io/controller=:NoSchedule --kube-reserved cpu=250m,memory=0.5Gi --system-reserved cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi,ephemeral-storage=1Gi --eviction-hard memory.available<500Mi,nodefs.available<10%'"
  },
  {
    name = "default"
    min_size = 3
    max_size = 9
    desired_capacity = 3
    instance_type = "t3.medium"
    key_name = "klefevre-sorrow"
    volume_size = 30
    volume_type = "gp2"
    autoscaling = "enabled"
    kubelet_extra_args = "--kubelet-extra-args '--node-labels node-role.kubernetes.io/node=\"\" --kube-reserved cpu=250m,memory=0.5Gi --system-reserved cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi,ephemeral-storage=1Gi --eviction-hard memory.available<500Mi,nodefs.available<10%'"
  },
]
```

### EKS addons module

By default everything is disabled for this module so no particular changes are required except for this part:

```json
eks = {
  "kubeconfig_path" = "./kubeconfig"
  "remote_state_bucket" = "sample-terraform-remote-state"
  "remote_state_key" = "sample/eks"
}  
```

This part should reflect your environment with your S3 bucket where the state fils are stored and also the key which is equivalent to the folder where the modules variables are defined, in our case `minimal/eks`.

## Planning the deployment

In the `minimal` folder:

```bash
terragrunt plan-all
terragrunt apply-all
```

Once completed, you should be able to access cluster:

```bash
export KUBECONFIG=$(pwd)/eks/kubeconfig
kubectl get nodes

NAME                                        STATUS   ROLES        AGE   VERSION
ip-10-0-29-11.eu-west-1.compute.internal    Ready    node         2d    v1.11.5
ip-10-0-49-90.eu-west-1.compute.internal    Ready    node         2d    v1.11.5
ip-10-0-59-209.eu-west-1.compute.internal   Ready    controller   2d    v1.11.5
ip-10-0-85-237.eu-west-1.compute.internal   Ready    node         2d    v1.11.5
```
