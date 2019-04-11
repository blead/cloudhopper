[host]
${hosts}
[host:vars]
ansible_ssh_extra_args='-o StrictHostKeyChecking=no'
ansible_ssh_private_key_file=~/.ssh/id_rsa.pem
ansible_ssh_user=ubuntu

[vpn]
${vpns}
[vpn:vars]
ansible_ssh_extra_args='-o StrictHostKeyChecking=no'
ansible_ssh_private_key_file=~/.ssh/id_rsa.pem
ansible_ssh_user=ubuntu
