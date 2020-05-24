provider "azurerm" {
  version = "=1.24.0"
}

resource "azurerm_resource_group" "live_migration" {
  name     = "live-migration-resource-group"
  location = "Southeast Asia"
}

resource "azurerm_virtual_network" "live_migration" {
  name                = "live-migration-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.live_migration.location}"
  resource_group_name = "${azurerm_resource_group.live_migration.name}"
}

resource "azurerm_subnet" "live_migration" {
  name                      = "internal"
  resource_group_name       = "${azurerm_resource_group.live_migration.name}"
  virtual_network_name      = "${azurerm_virtual_network.live_migration.name}"
  address_prefix            = "10.0.1.0/24"
  lifecycle {
    ignore_changes = ["network_security_group_id", "route_table_id"]
  }
}

resource "azurerm_route_table" "live_migration" {
  name                = "live-migration-route-table"
  location            = "${azurerm_resource_group.live_migration.location}"
  resource_group_name = "${azurerm_resource_group.live_migration.name}"

  route {
    name                   = "to-aws"
    address_prefix         = "${aws_vpc.default.cidr_block}"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${azurerm_network_interface.vpn.private_ip_address}"
  }
}

resource "azurerm_subnet_network_security_group_association" "live_migration_subnet_sg" {
  network_security_group_id = "${azurerm_network_security_group.all.id}"
  subnet_id                 = "${azurerm_subnet.live_migration.id}"
}

resource "azurerm_subnet_route_table_association" "live_migration_subnet_rt" {
  route_table_id = "${azurerm_route_table.live_migration.id}"
  subnet_id      = "${azurerm_subnet.live_migration.id}"
}

resource "azurerm_public_ip" "host" {
  name                         = "host-pip"
  location                     = "${azurerm_resource_group.live_migration.location}"
  resource_group_name          = "${azurerm_resource_group.live_migration.name}"
  allocation_method            = "Dynamic"
}

resource "azurerm_network_interface" "host" {
  name                = "host-nic"
  location            = "${azurerm_resource_group.live_migration.location}"
  resource_group_name = "${azurerm_resource_group.live_migration.name}"

  ip_configuration {
    name                          = "host-ip-config"
    subnet_id                     = "${azurerm_subnet.live_migration.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.host.id}"
  }
}

resource "azurerm_public_ip" "vpn" {
  name                         = "vpn-pip"
  location                     = "${azurerm_resource_group.live_migration.location}"
  resource_group_name          = "${azurerm_resource_group.live_migration.name}"
  allocation_method            = "Static"
}

resource "azurerm_network_interface" "vpn" {
  name                = "vpn-nic"
  location            = "${azurerm_resource_group.live_migration.location}"
  resource_group_name = "${azurerm_resource_group.live_migration.name}"

  ip_configuration {
    name                          = "vpn-ip-config"
    subnet_id                     = "${azurerm_subnet.live_migration.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.vpn.id}"
  }
}

resource "azurerm_virtual_machine" "host" {
  name                             = "host"
  location                         = "${azurerm_resource_group.live_migration.location}"
  resource_group_name              = "${azurerm_resource_group.live_migration.name}"
  network_interface_ids            = ["${azurerm_network_interface.host.id}"]
  vm_size                          = "Standard_D1_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "hostosdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "live-migration-host"
    admin_username = "ubuntu"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = "${file(var.public_key_path)}"
      path     = "/home/ubuntu/.ssh/authorized_keys"
    }
  }
}

resource "azurerm_virtual_machine" "vpn" {
  name                             = "vpn"
  location                         = "${azurerm_resource_group.live_migration.location}"
  resource_group_name              = "${azurerm_resource_group.live_migration.name}"
  network_interface_ids            = ["${azurerm_network_interface.vpn.id}"]
  vm_size                          = "Standard_D1_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "vpnosdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "live-migration-vpn"
    admin_username = "ubuntu"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = "${file(var.public_key_path)}"
      path     = "/home/ubuntu/.ssh/authorized_keys"
    }
  }
}
