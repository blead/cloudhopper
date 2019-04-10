data "template_file" "ansible_aws_host" {
  template = "${file("${path.module}/host.tpl")}"
  vars {
    public_ip  = "${aws_instance.host.public_ip}"
    private_subnet = "${aws_subnet.default.cidr_block}"
  }
}

data "template_file" "ansible_azure_host" {
  template = "${file("${path.module}/host.tpl")}"
  vars {
    public_ip  = "${azurerm_public_ip.host.ip_address}"
    private_subnet = "${azurerm_subnet.live_migration.address_prefix}"
  }
}

data "template_file" "ansible_aws_vpn" {
  template = "${file("${path.module}/host.tpl")}"
  vars {
    public_ip  = "${aws_instance.vpn.public_ip}"
    private_subnet = "${aws_subnet.default.cidr_block}"
  }
}

data "template_file" "ansible_azure_vpn" {
  template = "${file("${path.module}/host.tpl")}"
  vars {
    public_ip  = "${azurerm_public_ip.vpn.ip_address}"
    private_subnet = "${azurerm_subnet.live_migration.address_prefix}"
  }
}

data "template_file" "ansible_inventory" {
  template = "${file("${path.module}/inventory.tpl")}"
  vars {
    hosts = "${join("",list(data.template_file.ansible_aws_host.rendered, data.template_file.ansible_azure_host.rendered))}"
    vpns = "${join("",list(data.template_file.ansible_aws_vpn.rendered, data.template_file.ansible_azure_vpn.rendered))}"
    private_key_file = "${var.private_key_path}"
    ssh_user = "ubuntu"
  }
}

output "ansible_inventory" {
	value = "${data.template_file.ansible_inventory.rendered}"
}
