terraform {
  required_version = ">= 1.5.0"
  required_providers {
    ionoscloud = {
      source  = "ionos-cloud/ionoscloud"
      version = "~> 6.7"
    }
  }
}

provider "ionoscloud" {}

variable "name" {
  type    = string
  default = "uvv-unterweisungen"
}

variable "location" {
  description = "IONOS location, for example de/fra."
  type        = string
  default     = "de/fra"
}

variable "image_name" {
  description = "Image name or alias offered by the IONOS contract."
  type        = string
}

variable "ssh_public_key" {
  description = "Public SSH key to inject into the Linux image."
  type        = string
}

variable "ssh_allowed_ipv4" {
  description = "Single public IPv4 address allowed to reach SSH (without /32)."
  type        = string
}

variable "ssh_user" {
  type    = string
  default = "root"
}

variable "ssh_private_key_file" {
  type    = string
  default = "~/.ssh/id_ed25519"
}

variable "cores" {
  type    = number
  default = 2
}

variable "ram_mb" {
  type    = number
  default = 4096
}

variable "disk_gb" {
  type    = number
  default = 40
}

resource "ionoscloud_datacenter" "uvv" {
  name     = var.name
  location = var.location
}

resource "ionoscloud_lan" "public" {
  datacenter_id = ionoscloud_datacenter.uvv.id
  name          = "public"
  public        = true
}

resource "ionoscloud_ipblock" "public" {
  location = var.location
  size     = 1
  name     = "${var.name}-public-ip"
}

resource "ionoscloud_server" "uvv" {
  name         = var.name
  datacenter_id = ionoscloud_datacenter.uvv.id
  type         = "VCPU"
  cores        = var.cores
  ram          = var.ram_mb
  image_name   = var.image_name
  ssh_keys     = [var.ssh_public_key]

  volume {
    name              = "system"
    size              = var.disk_gb
    disk_type         = "SSD Standard"
    bus               = "VIRTIO"
    availability_zone = "AUTO"
    licence_type      = "LINUX"
  }

  nic {
    lan             = ionoscloud_lan.public.id
    name            = "public"
    dhcp            = true
    ips             = [ionoscloud_ipblock.public.ips[0]]
    firewall_active = true
    firewall_type   = "INGRESS"

    firewall {
      protocol         = "TCP"
      name             = "SSH administrator"
      port_range_start = 22
      port_range_end   = 22
      source_ip        = var.ssh_allowed_ipv4
      type             = "INGRESS"
    }

    firewall {
      protocol         = "TCP"
      name             = "HTTP"
      port_range_start = 80
      port_range_end   = 80
      type             = "INGRESS"
    }

    firewall {
      protocol         = "TCP"
      name             = "HTTPS"
      port_range_start = 443
      port_range_end   = 443
      type             = "INGRESS"
    }
  }
}

output "server_ipv4" {
  value = ionoscloud_server.uvv.primary_ip
}

output "ansible_inventory_ini" {
  value = "[uvv]\n${var.name} ansible_host=${ionoscloud_server.uvv.primary_ip} ansible_user=${var.ssh_user} ansible_ssh_private_key_file=${var.ssh_private_key_file}\n"
}
