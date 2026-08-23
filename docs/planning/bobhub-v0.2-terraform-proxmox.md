# BobHub v0.2.0 — Terraform + Proxmox

## Status

```text
✅ Completed
```

---

## Objective

BobHub v0.2.0 introduced Infrastructure as Code into the project using Terraform with Proxmox.

The objective was to move from manually prepared infrastructure toward a documented and reproducible virtual machine provisioning workflow.

The primary goal of this version was to validate the complete infrastructure provisioning path:

```text
Terraform
    ↓
Proxmox Provider
    ↓
Proxmox API
    ↓
Virtual Machine Provisioning
```

Application deployment and guest operating system configuration were intentionally kept outside the main scope.

---

## Context

BobHub v0.1.0 established the initial project foundation with:

- Docker
- Docker Compose
- Prometheus
- Grafana
- Node Exporter
- Alertmanager
- Discord alerting
- WireGuard
- Portainer
- Nginx Proxy Manager
- Uptime Kuma
- BobHub CLI
- Infrastructure documentation
- GitHub Issues
- Pull Request workflow
- GitHub Actions

BobHub v0.2.0 introduced the next infrastructure layer:

```text
Infrastructure as Code
```

The project moved from infrastructure operated primarily through manual configuration toward infrastructure represented and provisioned through code.

---

## Completed Scope

BobHub v0.2.0 delivered:

- Proxmox lab architecture documentation
- Proxmox lab baseline
- Terraform project structure
- Proxmox provider configuration
- Dedicated Terraform authentication
- Custom least-privilege Proxmox role
- VM variable definitions
- Sanitized `terraform.tfvars.example`
- BobHub VM resource definition
- Terraform state strategy
- Terraform operational runbook
- First VM provisioning validation
- Sensitive file protection
- Nested virtualization documentation
- Git workflow improvements
- Technical checkpoint documentation

---

## Architecture

The validated provisioning flow is:

```text
Terraform Configuration
        ↓
Proxmox Provider
        ↓
API Authentication
        ↓
Proxmox API
        ↓
Proxmox Node
        ↓
Storage
        ↓
Network Bridge
        ↓
Virtual Machine
```

This workflow was successfully tested.

---

# Proxmox Lab Architecture

The Proxmox environment used during v0.2.0 runs as a nested virtualization lab.

```text
Windows 11
    ↓
VirtualBox
    ↓
Proxmox VE
    ↓
QEMU
    ↓
Guest VM
```

The environment was created specifically to practice Proxmox administration and Infrastructure as Code without requiring dedicated physical virtualization hardware.

---

## Proxmox Baseline

The lab baseline includes:

- Proxmox VE
- Node configuration
- Local ISO storage
- Local LVM storage
- Network bridge
- Terraform API identity
- Dedicated API token
- Custom least-privilege role

The Proxmox node used during the lab is:

```text
pve
```

Environment-specific access information is intentionally not documented in the public repository.

---

# Terraform Project Structure

The Terraform implementation is located under:

```text
terraform/
└── proxmox/
```

The project contains:

```text
terraform/proxmox/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars.example
└── README.md
```

The structure separates:

- Provider configuration
- Input variables
- Environment-specific values
- Infrastructure resources
- Outputs

---

# Terraform Provider

BobHub uses the Proxmox Terraform provider to communicate with the Proxmox API.

The provider baseline uses:

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }
  }
}
```

Provider configuration:

```hcl
provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}
```

Credentials are provided through environment-specific configuration and are not hardcoded in the Terraform source.

---

# Terraform Authentication

Terraform uses a dedicated Proxmox identity:

```text
terraform@pve
```

A dedicated API token is used instead of administrator credentials.

A custom Terraform role was also created to practice least-privilege infrastructure automation.

The authentication flow is:

```text
Terraform
    ↓
API Token
    ↓
terraform@pve
    ↓
Custom Terraform Role
    ↓
Proxmox API
```

This avoids using root credentials for normal Infrastructure as Code operations.

---

# VM Definition

The first BobHub VM was defined using Terraform.

The resource validates infrastructure parameters including:

- VM name
- VM ID
- CPU
- Memory
- Disk
- Storage
- Network interface
- Proxmox bridge
- Boot configuration

The VM used during validation was:

```text
VM ID: 100
Name: lab-vm-01
```

Values are intentionally configurable through Terraform variables.

---

# VM Provisioning Validation

The first VM provisioning workflow was successfully executed.

The operational sequence was:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Terraform successfully communicated with the Proxmox API and created the virtual machine.

This validated:

```text
HCL Configuration
      ↓
Terraform Provider
      ↓
Authentication
      ↓
Proxmox API
      ↓
Node
      ↓
Storage
      ↓
Network
      ↓
VM Creation
```

This was the primary technical objective of BobHub v0.2.0.

---

# Terraform State Strategy

BobHub v0.2.0 uses local Terraform state.

Terraform creates files such as:

```text
terraform.tfstate
terraform.tfstate.backup
```

These files are not versioned.

Sensitive and environment-specific files are excluded from Git:

```text
terraform.tfvars
*.tfstate
*.tfstate.backup
.terraform/
```

The repository versions only sanitized configuration examples such as:

```text
terraform.tfvars.example
```

A remote Terraform backend may be introduced in a future BobHub version when multiple environments or collaborative workflows make it useful.

---

# Terraform Operational Workflow

The documented Terraform workflow is:

```text
Initialize
    ↓
Validate
    ↓
Plan
    ↓
Review
    ↓
Apply
    ↓
Validate Infrastructure
```

Commands:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

For lab cleanup:

```bash
terraform destroy
```

Infrastructure destruction should always be reviewed before confirmation.

---

# Security Considerations

BobHub v0.2.0 introduced explicit security practices around Infrastructure as Code.

The repository must not intentionally expose:

- Proxmox credentials
- API tokens
- Terraform state
- Real `terraform.tfvars`
- SSH private keys
- Sensitive IP addresses
- Sensitive hostnames
- Environment-specific credentials

Only sanitized examples should be committed.

The project also avoids using administrator credentials when a dedicated automation identity can be used.

---

# Nested Virtualization Limitation

The lab architecture does not expose hardware-assisted KVM virtualization to the nested Proxmox host.

As a result:

```text
/dev/kvm
```

is not available inside Proxmox.

The virtual machine therefore required software emulation.

The configuration used was:

```bash
qm set 100 --kvm 0
```

This allowed the VM to run without hardware-assisted KVM virtualization.

The limitation affects performance and guest compatibility but does not prevent Terraform from validating the infrastructure provisioning workflow.

---

# Ubuntu Guest Limitation

Ubuntu Server was used as the guest operating system during the provisioning test.

The nested environment presented the following boot error:

```text
IO-APIC + timer doesn't work!
```

During installation, the following kernel parameter allowed the process to continue:

```text
noapic
```

Additional guest boot issues were later observed after installation.

These issues were considered limitations of the nested virtualization environment.

They were not treated as blockers for BobHub v0.2.0 because the primary objective was:

```text
Terraform
↓
Proxmox API
↓
VM Provisioning
```

That objective was successfully achieved.

Guest operating system troubleshooting and configuration management remain separate concerns.

---

# Git Workflow Improvements

BobHub v0.2.0 also improved the repository development workflow.

Current helpers include:

```text
scripts/git/
├── start-issue.ps1
├── git-commit-push.ps1
├── open-pr.ps1
├── finish-pr.ps1
└── import-issues.sh
```

The current development workflow is:

```text
GitHub Issue
      ↓
start-issue.ps1
      ↓
Feature Branch
      ↓
Implementation
      ↓
git-commit-push.ps1
      ↓
Pull Request
      ↓
GitHub Actions
      ↓
Merge
      ↓
Issue Finalization
      ↓
finish-pr.ps1
```

This improves traceability between technical work and GitHub history.

---

# Out of Scope

The following items were intentionally not required for BobHub v0.2.0:

- Ansible configuration management
- Application deployment
- Kubernetes
- Production-grade High Availability
- Multi-node Proxmox clusters
- Public cloud infrastructure
- Multi-cloud architecture
- Advanced network automation
- Dedicated secrets management platform
- Automated Terraform deployment pipeline
- Production virtualization performance

These topics remain available for future BobHub versions.

---

# Success Criteria

BobHub v0.2.0 success criteria:

- [x] Proxmox architecture documented
- [x] Terraform folder structure created
- [x] Proxmox provider configured
- [x] Terraform variables defined
- [x] Sanitized tfvars example created
- [x] Terraform state strategy documented
- [x] Terraform runbook created
- [x] VM resource defined
- [x] Terraform plan validated
- [x] Terraform apply validated
- [x] First VM provisioned
- [x] Sensitive Terraform files ignored by Git
- [x] Dedicated Terraform authentication implemented
- [x] Least-privilege role implemented
- [x] Nested virtualization limitation documented
- [x] Technical checkpoint created

Result:

```text
✅ BobHub v0.2.0 objectives achieved
```

---

# Lessons Learned

BobHub v0.2.0 demonstrated that Infrastructure as Code involves more than writing Terraform resources.

The implementation required understanding:

```text
Terraform
    +
Provider
    +
API Authentication
    +
Permissions
    +
Virtualization
    +
Storage
    +
Networking
    +
State
    +
Security
```

Practical troubleshooting was an important part of the implementation.

The nested virtualization limitations also demonstrated that successful infrastructure provisioning does not automatically guarantee that every guest operating system scenario will behave like production hardware.

---

# Version Result

Before BobHub v0.2.0:

```text
Infrastructure
mostly prepared manually
```

After BobHub v0.2.0:

```text
Infrastructure Definition
        ↓
Terraform
        ↓
Provider
        ↓
API
        ↓
Reproducible Provisioning
```

BobHub now has a practical Infrastructure as Code foundation that can be extended to additional platforms.

---

# Next Version

## BobHub v0.3.0 — Multi-Cloud IaC, Security & Resilience

BobHub v0.3.0 will expand the Terraform foundation from the local Proxmox lab into public cloud environments.

Planned platforms:

```text
AWS
OCI
Azure
```

The next version will focus on combining Infrastructure as Code with:

- Cloud networking
- Multi-cloud architecture
- WAF
- Load balancing
- Traefik
- Global DNS
- Hybrid networking
- High Availability
- Disaster Recovery
- Centralized observability
- RTO and RPO
- FinOps

Conceptual evolution:

```text
BobHub v0.1
Infrastructure / Containers / Observability
                ↓
BobHub v0.2
Terraform + Proxmox
                ↓
BobHub v0.3
Multi-Cloud IaC
Security
Resilience
```

Ansible remains an important future BobHub track but is no longer the immediate next version.

---

# Conclusion

BobHub v0.2.0 successfully introduced Terraform and Infrastructure as Code into the project.

The version validated a complete provisioning workflow from Terraform configuration to a Proxmox virtual machine.

The project now has practical evidence involving:

- Terraform
- Infrastructure as Code
- Proxmox
- Terraform providers
- Terraform variables
- Terraform state
- API authentication
- Least privilege
- VM provisioning
- Infrastructure troubleshooting
- Operational runbooks
- Git-based infrastructure workflows

BobHub v0.2.0 is considered complete and ready for release.