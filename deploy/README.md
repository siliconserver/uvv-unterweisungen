# Deployment

This directory contains deployment automation for the UVV Unterweisungen app.
The same Ansible playbook deploys to AlmaLinux or Debian, whether Terraform has
created the VPS or the VPS already exists.

## Supported paths

1. **Create a VPS with Terraform:** use one provider directory under
   `terraform/` and then run Ansible against its IP address.
2. **Use an existing VPS:** use `terraform/existing` to produce an Ansible
   inventory, or write the host directly in `ansible/inventory.ini`.

Terraform providers are vendor-specific. The initial create-VM examples cover
Hetzner Cloud, IONOS Cloud, and Contabo. The existing-server path works with
any provider that gives you a Linux VPS with SSH and sudo/root access. The
practical German VPS shortlist is Hetzner, IONOS, STRATO, Contabo, netcup,
dogado, centron, webgo, Alfahosting, and IP-Projects; it is a working scope,
not a measured market-share ranking. Some vendors expose no API for ordering
VMs, so Terraform cannot create those VMs automatically. See
`terraform/README.md` for the provider notes.

## Minimum starting size

Use at least 2 vCPU, 2 GB RAM, and 20 GB persistent disk for a small
installation. These are planning defaults, not limits published by the app.
The actual provider plan may be larger. The app's SQLite database, logo, and
session key must live on persistent storage.

## Deploy to an existing VPS

1. Install Terraform and Ansible on the control machine.
2. Edit `ansible/group_vars/all.yml`.
3. Copy `ansible/secrets.yml.example` to `ansible/secrets.yml`, set the initial
   admin password and optional SMTP password, and encrypt it with Ansible Vault:

   ```sh
   cd deploy/ansible
   cp secrets.yml.example secrets.yml
   ansible-vault encrypt secrets.yml
   ```

4. Copy `inventory.ini.example` to `inventory.ini`, then enter the VPS address
   and SSH user. Keep the matching private SSH key on the control machine.
5. Install the Ansible collection and deploy:

   ```sh
   ansible-galaxy collection install -r requirements.yml
   ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass
   ```

The playbook defaults to Caddy in a Docker container, with automatic HTTPS.
Point the domain's A/AAAA records to the VPS and allow inbound TCP 80 and 443.
For an existing proxy, set `uvv_proxy_mode: external`; the app then binds to
`uvv_bind_address` and `uvv_http_port`.

AlmaLinux is the preferred default for new Hetzner servers, and Debian is also
supported by the playbook. Docker's installation guide lists Debian, RHEL, and
CentOS as supported platforms but says it does not test or verify derivative
distributions. The AlmaLinux task uses Docker's CentOS-compatible RPM
repository; Debian is the directly listed path.

The host firewall can be managed by Ansible. Before enabling the playbook,
set `uvv_ssh_allowed_cidrs` to the administrator's public IP/CIDR so the
firewall does not lock out SSH. Provider firewalls should allow TCP 22 from
those same ranges and TCP 80/443 from the Internet when Caddy is enabled.
When reusing a VPS that already serves other ports, review its firewall policy
before leaving `uvv_manage_host_firewall: true`; the playbook allows SSH from
the configured CIDRs and inbound web traffic on ports 80 and 443.

## Create a VPS with Terraform

Choose exactly one directory: `terraform/hetzner`, `terraform/ionos`, or
`terraform/contabo`. Copy that directory's `terraform.tfvars.example` to
`terraform.tfvars`, fill in the required provider-specific values, and supply
credentials through environment variables as described in its README. Then:

```sh
terraform init
terraform plan
terraform apply
terraform output -raw ansible_inventory_ini > ../../ansible/inventory.ini
```

Review the plan before applying it. The Contabo product and image identifiers
must match the selected contract and the image catalog in that account.

## Backups and updates

The playbook installs a daily SQLite online backup by default. It archives the
database, logo, and generated session key to `uvv_backup_dir`; old archives are
removed after `uvv_backup_retention_days`. Copy backups off the VPS for disaster
recovery.

The app image tag is configurable as `uvv_image_tag`. A fixed release tag is
recommended for controlled updates. After changing it, rerun the playbook.
The admin password in `secrets.yml` only bootstraps the first account; changing
it later in Ansible does not reset an existing account.

## Notes

- `COOKIE_SECURE` stays enabled because the public URL uses HTTPS. The local
  development exception `COOKIE_SECURE=0` is not used here.
- Do not commit `secrets.yml`, `terraform.tfvars`, Terraform state files, or
  private SSH keys.
- The app uses SQLite in a local data directory. Run one app instance per data
  directory; this setup does not configure a multi-node database.
