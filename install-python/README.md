# Live Migration: Install Python

For Ansible to work at full capacity. Python needs to be installed on every instance.

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

Start provisioning:

```sh
ansible-playbook -i hosts playbook.yaml
```
