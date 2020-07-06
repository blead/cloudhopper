# Live Migration: OCI Container

This extracts each container image and starts it on the source host. For this to work, source host needs to be supplied to Ansible via variables (`-e` option).

## Images

Images are released as pre-configured archives. See [releases](https://github.com/blead/live-migration/releases/).

Note that credentials for database access are hard coded, and thus not secure. Do not use this in production environment.

For instructions on creating images, see: [IMAGESHOWTO.md](IMAGESHOWTO.md).

## Inventory

Inventory file can be copied from the output of [Infrastructure](../infrastructure) section:

```sh
cp ../infrastructure/aws-gcp/hosts ./hosts
```

Otherwise, manually create a new file. See [`hosts.example`](hosts.example) for an example.

## Provision

Before provisioning, set up the SSH agent. For example, if the private key is `~/.ssh/id_rsa.pem`:

```sh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa.pem
```

From the inventory, pick the source host to start container.

Start provisioning:

```sh
ansible-playbook -i hosts -e source=8.9.10.11 playbook.yaml
```
