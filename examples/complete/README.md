# Complete Example: EKS Cluster Deployment with new VPC & Big Bang Dependencies

This example deploys:

- A VPC with:
  - 3 public subnets with internet gateway
  - 3 private subnets with NAT gateway
- An EKS cluster with worker node group(s)
- A Bastion host in one of the private subnets
- Big Bang dependencies:
  - KMS key and IAM roles for SOPS and IRSA
  - S3 bucket for Loki
  - RDS database for Keycloak

## How to Deploy

### Prerequisites

- *Nix operating system (Linux, macOS, WSL2)
- AWS CLI environment variables
  - At minimum: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and either `AWS_REGION` or `AWS_DEFAULT_REGION`
  - Preferred: the above plus `AWS_SESSION_TOKEN`, `AWS_SECURITY_TOKEN`, and `AWS_SESSION_EXPIRATION`
  > If the account is set up to require MFA, you'll be required to have the session stuff. We recommend that you use [aws-vault](https://github.com/99designs/aws-vault). Friends don't let friends use unencrypted AWS creds.
- `docker`
- `make`
- various standard CLI tools that usually come with running on *Nix (grep, sed, etc)

### Configure

- If you want access to the cluster, update the `aws_admin_usernames` variable in `fixtures.common.tfvars` to include your IAM username.
  > Easily retrieve your IAM username with `aws iam get-user | jq '.[]' | jq -r '.UserName'`
- Feel free to change other variables to suit your needs.

### Deploy

We'll be using our automated tests to stand up environments. They use [Terratest](https://github.com/gruntwork-io/terratest). Each test is based on one of examples in the `examples` directory. For example, if you want to stand up the "complete" example in "insecure" mode, you'll run the `test-complete-insecure` target.

```shell
export SKIP_TEARDOWN=1
unset SKIP_SETUP
unset SKIP_TEST
make test-complete-insecure
```
> `SKIP_TEARDOWN` tells Terratest to skip running the test stage called "TEARDOWN", which is the stage that destroys the environment. We want things to stay up, so we set this variable. We also make sure `SKIP_SETUP` and `SKIP_TEST` are unset.

> Run `make help` to see all the available targets. Any of them can be used to stand up an environment with different parameters. Do not run `make test` directly, as it will run all the tests in parallel and is not compatible with `SKIP_TEARDOWN`.

### Destroy

```shell
unset SKIP_TEARDOWN
export SKIP_SETUP=1
export SKIP_TEST=1
make test-complete-insecure
```
> Since we're tearing down this time, we don't want `SKIP_TEARDOWN` to be set. Instead, we are setting `SKIP_SETUP` and `SKIP_TEST` to skip the setup and test stages.
