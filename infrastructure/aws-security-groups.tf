resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh"
  description = "Allow SSH. Managed by Terraform."
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow-http"
  description = "Allow HTTP. Managed by Terraform."
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_internal" {
  name        = "allow-internal"
  description = "Allow internal traffic within VPC. Managed by Terraform."
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${aws_vpc.default.cidr_block}"]
  }
}

resource "aws_security_group" "allow_azure" {
  name        = "allow-azure"
  description = "Allow traffic from Azure. Managed by Terraform."
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${azurerm_virtual_network.live_migration.address_space}"]
  }
}

resource "aws_security_group" "allow_azure_vpn" {
  name        = "allow-azure-vpn"
  description = "Allow traffic from Azure VPN gateway. Managed by Terraform."
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${azurerm_public_ip.vpn.ip_address}/32"]
  }
}

resource "aws_security_group" "allow_egress" {
  name        = "allow-egress"
  description = "Allow outgoing traffic. Managed by Terraform."
  vpc_id      = "${aws_vpc.default.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
