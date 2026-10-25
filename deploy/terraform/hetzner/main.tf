terraform {
  required_version = ">= 1.5.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.70"
    }
  }
}

provider "hcloud" {}

variable "name" {
  type    = string
  default = "uvv-unterweisungen"
}

variable "location" {
  description = "Hetzner Cloud location, for example nbg1, fsn1, or hel1."
  type        = string
  default     = "nbg1"
}

variable "server_type" {
  description = "Hetzner server type; cx23 is a 2 vCPU / 4 GB / 40 GB starting plan."
  type        = string
  default     = "cx23"
}

variable "image" {
  description = "Hetzner system image. Use alma-10 by default or debian-13."
  type        = string
  default     = "alma-10"
}

variable "ssh_user" {
  type    = string
  default = "root"
}

variable "ssh_public_key" {
  description = "Public SSH key to install on the new server."
  type        = string
}

variable "ssh_private_key_file" {
  description = "Private key path on the Ansible control machine."
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "ssh_allowed_cidrs" {
  description = "Source CIDRs permitted to connect to SSH."
  type        = list(string)
  validation {
    condition     = length(var.ssh_allowed_cidrs) > 0
    error_message = "Set ssh_allowed_cidrs to at least one administrator IP/CIDR."
  }
}

resource "hcloud_ssh_key" "admin" {
  name       = "${var.name}-admin"
  public_key = var.ssh_public_key
}

resource "hcloud_firewall" "uvv" {
  name = "${var.name}-firewall"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.ssh_allowed_cidrs
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "uvv" {
  name        = var.name
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.admin.id]
  firewall_ids = [
    hcloud_firewall.uvv.id,
  ]
}

output "server_ipv4" {
  value = hcloud_server.uvv.ipv4_address
}

output "ansible_inventory_ini" {
  value = "[uvv]\n${var.name} ansible_host=${hcloud_server.uvv.ipv4_address} ansible_user=${var.ssh_user} ansible_ssh_private_key_file=${var.ssh_private_key_file}\n"
}
