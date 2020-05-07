# Live Migration: Infrastructure

## Directory

- [AWS-Azure infrastructure](aws-azure).
- [AWS-GCP infrastructure](aws-gcp).

Documentation will assume AWS-GCP. Differences are very minimal between the 2 setups.

## Authentication

### AWS

Authentication can be done with the shared credentials file in `~/.aws/credentials`.

See https://docs.aws.amazon.com/ses/latest/DeveloperGuide/create-shared-credentials-file.html.

For other methods, see: https://www.terraform.io/docs/providers/aws/index.html#authentication.

(Untested) The following policies are needed for the user:
- AmazonEC2FullAccess
- AmazonVPCFullAccess

### Azure

Authentication can be done with Azure CLI.

See https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest.

After the installation, run:

```sh
az login
```

For other methods, see: https://www.terraform.io/docs/providers/azurerm/index.html#authenticating-to-azure.

### GCP

- Create a service account for your project
- Download the provided JSON file
- Provide the JSON file path to the corresponding variable (`gcp_credentials_path`)

https://www.terraform.io/docs/providers/google/index.html

## SSH Key

To create an SSH key for use with instances:

```sh
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```
- Passphrase can be skipped.
- The generated keypair will be used as values of the corresponding variables (`public_key_path`, `private_key_path`).

## Variables

Create `terraform.tfvars` with the following variables:
- `key_name`
- `public_key_path`
- `private_key_path`
- `gcp_project_id` (AWS-GCP only)
- `gcp_credentials_path` (AWS-GCP only)

Refer to [`terraform.tfvars.example`](aws-gcp/terraform.tfvars.example).

## Provision

Before provisioning, set up the SSH agent. For example, if the private key is `~/.ssh/id_rsa.pem`:

```sh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa.pem
```

Note that if provisioning in regions other than ap-southeast-1, replace the following fields in `aws.tf`:
  - `region`: existing value is `ap-southeast-1`.
  - `ami`: existing value is `ami-0dad20bd1b9c8c004`, Ubuntu 18.04.

Initiate Terraform, if this is the first run.

```sh
terraform init
```

Start provisioning:

```sh
terraform apply
terraform output ansible_inventory > hosts
```

If there is anything wrong/missing in the inventory file, try executing `terraform apply` again.

This `hosts` file will be used as inventory file in other Ansible-based sections.

## Destroy

To destroy all provisioned resources:

```sh
terraform destroy
```
