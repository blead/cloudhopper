# Live Migration: Infrastructure

## Authentication

### AWS

Authentication can be done with the shared credentials file in `~/.aws/credentials`.

See https://docs.aws.amazon.com/ses/latest/DeveloperGuide/create-shared-credentials-file.html.

For other methods, see: https://www.terraform.io/docs/providers/aws/index.html#authentication.

### Azure

Authentication can be done with Azure CLI.

See https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest.

After the installation, run:

```sh
az login
```

For other methods, see: https://www.terraform.io/docs/providers/azurerm/index.html#authenticating-to-azure.

### Google

- Create a service account for your project
- Download the provided JSON file
- Provide the JSON file path to the corresponding variable

https://www.terraform.io/docs/providers/google/index.html

## Variables

Create `terraform.tfvars` with the following variables:
- `key_name`
- `public_key_path`
- `private_key_path`

Refer to [`terraform.tfvars.example`](terraform.tfvars.example).

## Provision

Before provisioning, set up the SSH agent. For example, if the private key is `~/.ssh/id_rsa.pem`:

```sh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa.pem
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
