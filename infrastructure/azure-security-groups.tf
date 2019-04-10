resource "azurerm_network_security_group" "all" {
  name                = "all-nsg"
  resource_group_name = "${azurerm_resource_group.live_migration.name}"
  location            = "${azurerm_resource_group.live_migration.location}"

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-internal"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = ["${azurerm_virtual_network.live_migration.address_space}"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-aws"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "${aws_vpc.default.cidr_block}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-aws-vpn"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix    = "${aws_instance.vpn.public_ip}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-egress"
    priority                   = 105
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix    = "*"
    destination_address_prefix = "*"
  }
}
