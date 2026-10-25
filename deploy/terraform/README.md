# Terraform provider notes

Terraform uses separate provider plugins for each cloud API; a single
provider-neutral `provider` switch cannot create machines across unrelated
VPS control panels. Each provider directory is therefore an independent root
module. Apply one directory, then use the shared Ansible playbook.

## Initial create-VM modules

| Provider | Create VM | Notes |
| --- | --- | --- |
| Hetzner Cloud | Yes | `hcloud_server`; AlmaLinux 10 is the default image. |
| IONOS Cloud | Yes | Creates a VDC, public LAN/IP, and VM. Set the image alias supported by the IONOS account. |
| Contabo | Yes | Requires a product ID, image ID, and SSH-key secret ID from the Contabo account. |
| netcup | No in this setup | Use the existing-server path; the SCP API does not create or delete VPS contracts. |
| dogado | No | Its current public Cloud Server API lists, reads, and powers existing servers; it does not order new ones. |
| STRATO, centron, webgo, Alfahosting, IP-Projects | Existing-server path | No validated create-VM Terraform adapter is included. |

The list is based on vendor APIs and Terraform provider resources, not on a
claim that all vendors have the same infrastructure capabilities. Community
providers may change independently of the vendor APIs. Review the plan and
provider documentation before applying.

## Existing VPS

`existing` does not create or change a server. It formats an inventory entry
from an IP/hostname and SSH user so the same Ansible playbook can be used:

```sh
cd deploy/terraform/existing
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
terraform output -raw ansible_inventory_ini > ../../ansible/inventory.ini
```

You can also skip this small helper and edit the Ansible inventory directly.

## Credentials and state

Set credentials in environment variables, not in committed `.tfvars` files:

- Hetzner: `HCLOUD_TOKEN`
- IONOS: `IONOS_TOKEN`
- Contabo: `CNTB_OAUTH2_CLIENT_ID`, `CNTB_OAUTH2_CLIENT_SECRET`,
  `CNTB_OAUTH2_USER`, `CNTB_OAUTH2_PASS`

Terraform state can contain infrastructure metadata and must be stored and
backed up securely. Do not commit state or `.tfvars` files. No remote backend
is selected here because the appropriate state service depends on the team.

## Provider-specific details

### Hetzner Cloud

The default `server_type` is `cx23` (2 vCPU, 4 GB RAM, 40 GB disk), a plan
larger than the app's initial planning baseline. `server_type`, `image`, and
`location` are variables. `alma-10` is used by default; set `image =
"debian-13"` for Debian. The cloud firewall permits TCP 22 only from
`ssh_allowed_cidrs`, and TCP 80/443 from the Internet.

### IONOS Cloud

The module defaults to 2 vCPU, 4 GB RAM, and a 40 GB SSD. `image_name` must
match an image or alias available to the IONOS contract. The VM receives a
public address and the public SSH key. Set `ssh_allowed_ipv4` to the
administrator's public IPv4 address without a CIDR suffix; IONOS firewall
rules accept one IPv4 source address per rule. The Ansible host firewall can
also restrict SSH to `uvv_ssh_allowed_cidrs`.

### Contabo

Set `product_id`, `image_id`, and `ssh_key_secret_ids` for the chosen Contabo
account. These catalog IDs are account/product-specific; the Terraform
provider cannot infer the desired plan from generic CPU/RAM/disk values.
