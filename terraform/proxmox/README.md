# BobHub Terraform — Proxmox

This directory contains the Terraform configuration used by BobHub to provision infrastructure in the Proxmox lab.

## Purpose

The goal of this directory is to provide a reproducible Infrastructure as Code structure for the BobHub v0.2.0 Terraform + Proxmox track.

Terraform will be responsible for provisioning virtual infrastructure.

Operating system configuration and application deployment are outside the scope of this directory and may be handled by future automation such as Ansible.

## Structure

```text
terraform/proxmox/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars.example
└── README.md

## Provider

BobHub uses the `bpg/proxmox` Terraform provider to interact with the Proxmox VE API.

The provider configuration is stored in `providers.tf`.

## Authentication

The preferred authentication method is a dedicated Proxmox API token.

The provider receives authentication data through Terraform variables:

- `proxmox_endpoint`
- `proxmox_api_token`
- `proxmox_insecure`

Real credentials must never be committed to the repository.

For local development, values may be provided through a local `terraform.tfvars` file, which is ignored by Git.

Sensitive variables can also be provided through environment variables.

PowerShell example:

```powershell
$Env:TF_VAR_proxmox_endpoint = "https://pve.example.local:8006/"
$Env:TF_VAR_proxmox_api_token = "terraform@pve!provider=TOKEN"

## Terraform State Strategy

Terraform state stores the mapping between the resources defined in the configuration and the infrastructure managed by Terraform.

For the current lab stage, Terraform state is stored locally on the machine running Terraform.

Typical local state files include:

- `terraform.tfstate`
- `terraform.tfstate.backup`
- other files matching `*.tfstate.*`

These files must never be committed to Git.

The local `.gitignore` protects Terraform state files from accidental commits.

### Why state must not be committed

Terraform state may contain infrastructure metadata and values returned by providers.

Depending on the resources being managed, state files may include sensitive information such as:

- resource identifiers
- IP addresses
- infrastructure topology
- provider-generated attributes
- configuration values
- sensitive values referenced by managed resources

Marking a Terraform variable as `sensitive` prevents Terraform from displaying it in some CLI output, but it does not guarantee that the value will not be stored in the state.

For this reason, Terraform state must be treated as sensitive operational data.

### Current strategy

For the current Terraform + Proxmox lab:

- state is stored locally;
- state files are ignored by Git;
- real `.tfvars` files are ignored by Git;
- `.terraform.lock.hcl` remains versioned;
- only safe example values are committed.

This approach is sufficient while the environment is operated by a single user and remains a local lab.

### Future remote backend

If the Terraform environment becomes shared or used by multiple operators, the state should be migrated to a remote backend.

A remote backend can provide:

- centralized state storage;
- controlled access;
- state locking;
- better collaboration;
- backup and recovery capabilities.

The specific remote backend will be evaluated when the lab requires shared Terraform execution.
```