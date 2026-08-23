# BobHub Checkpoint — Terraform + Proxmox v0.2.0

## Status

Completed.

## Version

v0.2.0

---

## Overview

This checkpoint closes the BobHub v0.2.0 Terraform + Proxmox implementation.

The main objective of this version was to validate an Infrastructure as Code workflow capable of provisioning virtual machines in Proxmox using Terraform.

The focus of this release was infrastructure provisioning and reproducibility.

Guest operating system configuration and configuration management were intentionally kept outside the main scope.

---

## Architecture

The validated provisioning flow is:

```text
Terraform
    ↓
Proxmox Provider
    ↓
Proxmox API
    ↓
VM Resource Definition
    ↓
terraform plan
    ↓
terraform apply
    ↓
Proxmox VM
```

---

## Completed Scope

The following components were implemented and validated:

- Proxmox lab architecture documented
- Proxmox lab host installed and baselined
- Dedicated Terraform authentication strategy created
- Custom least-privilege Proxmox role configured
- Terraform project structure created
- Proxmox Terraform provider configured
- VM variables defined
- Safe `terraform.tfvars.example` created
- Terraform state strategy documented
- VM resource definition implemented
- Terraform operational runbook created
- First VM provisioning successfully executed
- Sensitive Terraform files protected from Git
- Git workflow helpers used during the implementation

---

## Terraform Project Structure

The v0.2.0 Terraform implementation is located under:

```text
terraform/
└── proxmox/
```

The implementation includes:

```text
main.tf
variables.tf
outputs.tf
providers.tf
terraform.tfvars.example
README.md
```

Environment-specific values are stored locally and are not committed.

---

## Terraform State Strategy

For BobHub v0.2.0, Terraform state is stored locally.

Sensitive and environment-specific files are excluded from Git, including:

```text
terraform.tfvars
*.tfstate
*.tfstate.backup
.terraform/
```

Only sanitized example configuration is versioned.

A remote backend may be introduced in a future version.

---

## Proxmox Authentication

Terraform uses a dedicated Proxmox API identity rather than administrator credentials.

The implementation uses:

```text
terraform@pve
```

with a dedicated API token and a custom Terraform role.

The objective was to validate a least-privilege authentication approach instead of using root credentials for infrastructure automation.

Real tokens and environment-specific values are not stored in the repository.

---

## VM Provisioning Validation

The first BobHub VM was successfully created through Terraform.

The validation confirmed the complete workflow:

```text
Terraform configuration
        ↓
Provider authentication
        ↓
Proxmox API
        ↓
Node
        ↓
Storage
        ↓
Network bridge
        ↓
VM creation
```

This confirmed that Terraform could manage the Proxmox lab environment successfully.

---

## Nested Virtualization Limitation

The Proxmox lab runs in a nested virtualization environment:

```text
Windows 11
    ↓
VirtualBox
    ↓
Proxmox VE
    ↓
QEMU VM
```

Hardware virtualization is not exposed to the nested Proxmox host.

As a result:

```text
/dev/kvm
```

is not available inside Proxmox.

The VM therefore required software emulation.

The following configuration was used:

```bash
qm set 100 --kvm 0
```

This allowed the VM provisioning workflow to continue without hardware-assisted KVM virtualization.

---

## Ubuntu Guest Limitation

The Ubuntu Server guest presented boot-related issues under nested software emulation.

During installation, the kernel parameter:

```text
noapic
```

was required to work around:

```text
IO-APIC + timer doesn't work!
```

Additional guest boot issues were later observed after installation.

These issues were considered limitations of the nested lab environment and were not treated as blockers for BobHub v0.2.0.

The objective of the version was to validate:

```text
Terraform
↓
Proxmox
↓
VM provisioning
```

That workflow was successfully validated.

Guest operating system troubleshooting is outside the final v0.2.0 scope.

---

## Operational Workflow

The Terraform operational workflow documented during this version is:

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

The project also documents safety considerations for Terraform state, secrets and environment-specific values.

---

## Security Considerations

The repository does not intentionally version:

- Proxmox API tokens
- Terraform state
- Real `terraform.tfvars`
- SSH private keys
- Sensitive network information
- Environment-specific credentials

Only sanitized examples and documentation are stored in Git.

---

## Result

BobHub v0.2.0 successfully introduced Infrastructure as Code into the project.

Before v0.2.0, the infrastructure provisioning process was primarily manual.

After v0.2.0, BobHub has a reproducible Terraform workflow capable of provisioning infrastructure through the Proxmox API.

The version demonstrates practical knowledge of:

- Infrastructure as Code
- Terraform
- Terraform providers
- Variables
- Terraform state
- API authentication
- Least privilege
- Proxmox automation
- Infrastructure documentation
- Git-based infrastructure workflows

---

## Version Conclusion

BobHub v0.2.0 is considered complete.

```text
BobHub v0.1
Infrastructure / Containers / Observability
                ↓
BobHub v0.2
Terraform + Proxmox
                ↓
BobHub v0.3
Multi-Cloud IaC, Security & Resilience
```

The next BobHub version will expand the Infrastructure as Code foundation into public cloud and multi-cloud architecture.