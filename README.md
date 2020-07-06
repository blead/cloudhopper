# Live Migration

This repository contains automation scripts used to perform a proof-of-concept container live migration across cloud providers with a specific setup.
It is divided into multiple steps which can be executed one after another.
The final step, "Reset Environment", can be executed to reset the environment to before "OCI Container" step for performing another migration.
Please note that the infrastructure step was implemented with **Terraform v0.11**.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v0.11)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Steps

- [Infrastructure](infrastructure)
- [Install Python](install-python)
- [IPsec VPN](ipsec-vpn)
- [Migration Host](migration-host)
- [OCI Container](oci-container)
- [Process Migration](process-migration)
- [Reset Environment](reset-environment)
