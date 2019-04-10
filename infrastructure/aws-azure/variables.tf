variable "key_name" {
  description = "Desired name of key pair."
}

variable "public_key_path" {
  description = "Path to the SSH public key to be used for authentication."
}

variable "private_key_path" {
  description = "Path to the SSH private key to be used for authentication."
}
