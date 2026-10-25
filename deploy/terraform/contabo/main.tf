terraform {
  required_version = ">= 1.5.0"
  required_providers {
    contabo = {
      source  = "contabo/contabo"
      version = "~> 0.1.44"
    }
  }
}

provider "contabo" {}

variable "name" {
  type    = string
  default = "uvv-unterweisungen"
}

variable "product_id" {
  description = "Contabo VPS/VDS product ID selected in the account."
  type        = string
}

variable "image_id" {
  description = "Contabo Linux image ID from the account image catalog."
  type        = string
}

variable "region" {
  type    = string
  default = "EU"
}

variable "contract_months" {
  type    = number
  default = 1
}

variable "ssh_key_secret_ids" {
  description = "Contabo secret IDs for public SSH keys uploaded in the account."
  type        = list(number)
}

variable "ssh_user" {
  description = "Contabo default administrative user; admin uses sudo."
  type        = string
  default     = "admin"
}

variable "ssh_private_key_file" {
  type    = string
  default = "~/.ssh/id_ed25519"
}

resource "contabo_instance" "uvv" {
  display_name = var.name
  product_id   = var.product_id
  image_id     = var.image_id
  region       = var.region
  period       = var.contract_months
  default_user = var.ssh_user
  ssh_keys     = var.ssh_key_secret_ids
}

output "server_ipv4" {
  value = contabo_instance.uvv.ip_config[0].v4[0].ip
}

output "ansible_inventory_ini" {
  value = "[uvv]\n${var.name} ansible_host=${contabo_instance.uvv.ip_config[0].v4[0].ip} ansible_user=${var.ssh_user} ansible_ssh_private_key_file=${var.ssh_private_key_file}\n"
}
