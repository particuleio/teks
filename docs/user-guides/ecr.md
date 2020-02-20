# ECR module

`ecr` is a custom module maintained [here](https://github.com/clusterfrak-dynamics/terraform-aws-ecr) and allows creation of AWS ECR repository to host docker images.

It provides:

* ECR repository
* ECR repository policy
* Custom IAM user with Access Key and Secret Key to be able to push images to ECR (eg. for CI purposes)

## Customization

Just like the other modules, custom configuration is done in `terragrunt.hcl`.

```json
{!terraform/live/demo/eu-west-3/ecr/terragrunt.hcl!}
```
