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