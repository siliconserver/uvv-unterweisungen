terraform {
  required_version = ">= 1.5.0"
}

variable "server_name" {
  description = "Inventory name for the existing VPS."
  type        = string
  default     = "uvv-server"
}

variable "server_address" {
  description = "IPv4 address or DNS name of the existing VPS."
  type        = string
}

variable "ssh_user" {
  description = "SSH account with root or sudo access."
  type        = string
  default     = "root"
}

variable "ssh_private_key_file" {
  description = "Private key path on the Ansible/Terraform control machine."
  type        = string
  default     = "~/.ssh/id_ed25519"
}

output "ansible_inventory_ini" {
  description = "Inventory entry to pass to the shared Ansible playbook."
  value       = "[uvv]\n${var.server_name} ansible_host=${var.server_address} ansible_user=${var.ssh_user} ansible_ssh_private_key_file=${var.ssh_private_key_file}\n"
}
