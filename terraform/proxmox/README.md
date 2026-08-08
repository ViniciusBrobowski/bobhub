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