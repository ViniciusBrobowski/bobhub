# BobHub v0.2.0 — Terraform + Proxmox

## Objective

BobHub v0.2.0 focuses on Infrastructure as Code using Terraform with Proxmox.

The goal is to move from manually prepared infrastructure to a documented and reproducible VM provisioning workflow.

This version will not focus on application deployment yet. The main objective is to create the foundation for provisioning virtual machines in Proxmox using code.

---

## Context

BobHub v0.1.0 created the foundation of the project:

- Docker-based lab environment
- Observability stack
- Prometheus
- Grafana
- Node Exporter
- Alertmanager
- Discord alerting
- BobHub CLI
- Infrastructure inventory generator
- Infrastructure report
- Observability runbook
- GitHub release helper

BobHub v0.2.0 starts the next layer: infrastructure provisioning.

---

## Scope

This version includes:

- Proxmox lab architecture documentation
- Terraform project structure
- Proxmox provider configuration
- VM variable definitions
- Example tfvars file
- BobHub VM resource definition
- Terraform state strategy documentation
- Terraform runbook
- First VM provisioning test

---

## Out of Scope

This version does not include:

- Ansible configuration management
- MyHub application deployment
- Kubernetes
- Production-grade HA
- Multi-node Proxmox cluster automation
- Advanced network automation
- Secret management platform integration
- Automated CI/CD pipeline for Terraform

These topics may be addressed in future BobHub versions.

---

## Target Architecture

Expected flow:

```text
Terraform
↓
Proxmox API
↓
VM Provisioning
↓
Ubuntu Server VM
↓
Future Ansible Configuration
↓
Future Docker/Application Hosting
```

---

## Expected VM Standard

Initial BobHub VM standard:

| Item | Value |
|---|---|
| Name | bobhub-lab-01 |
| Platform | Proxmox |
| OS | Ubuntu Server |
| CPU | 2 vCPU |
| Memory | 4 GB |
| Disk | 40 GB |
| Network | Proxmox bridge |
| Access | SSH |
| Purpose | BobHub lab VM |

Values may be adjusted according to available lab resources.

---

## Proposed Repository Structure

Expected Terraform structure:

```text
terraform/
└── proxmox/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── providers.tf
    ├── terraform.tfvars.example
    └── README.md
```

---

## State Strategy

For the first implementation, Terraform state will be stored locally.

Expected files:

```text
terraform.tfstate
terraform.tfstate.backup
```

These files must not be committed to Git.

The repository should version only safe configuration examples, such as:

```text
terraform.tfvars.example
```

Sensitive or environment-specific files must be ignored:

```text
terraform.tfvars
*.tfstate
*.tfstate.backup
.terraform/
```

A remote backend may be evaluated in a future version.

---

## Security Considerations

The Terraform implementation must not expose:

- Proxmox credentials
- API tokens
- Public IP addresses
- Private IP addresses
- SSH private keys
- Real hostnames if sensitive
- Terraform state files
- Environment-specific tfvars files

Only sanitized examples should be committed.

---

## Success Criteria

BobHub v0.2.0 is considered complete when:

- Proxmox architecture is documented
- Terraform folder structure exists
- Provider configuration is documented
- Variables are defined
- Example tfvars file exists
- Terraform state strategy is documented
- Terraform runbook exists
- At least one VM provisioning flow is tested or clearly documented
- Sensitive files are ignored by Git

---

## Future Versions

Expected next versions:

```text
BobHub v0.3.0 — Ansible
BobHub v0.4.0 — MyHub Product Hosting
```

Future flow:

```text
Terraform + Proxmox
↓
Ansible
↓
Docker Compose
↓
Observability
↓
MyHub
```