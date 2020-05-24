# Live Migration: IPSec VPN

This sets up a VPN connection between each VPN instances.

## Warning

As can be seen from [`ipsec.secrets.j2`](roles/strongswan/templates/ipsec.secrets.j2) template, the password used for the VPN is not secure. Consider changing it in production environments.

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
