# BobHub Proxmox Lab Architecture

## Overview

Proxmox is the virtualization layer used by BobHub for the Infrastructure as Code track introduced in BobHub v0.2.0.

Its role is to provide the target infrastructure where Terraform can create and manage virtual machines in a reproducible and documented way.

The goal of this architecture is not to reproduce a production environment, but to provide a controlled lab where infrastructure provisioning concepts can be practiced and validated.

The current BobHub implementation uses a nested virtualization architecture for learning purposes.

```text
Windows 11
    ↓
VirtualBox
    ↓
Proxmox VE
    ↓
Terraform via Proxmox API
    ↓
Virtual Machines
```

This architecture is specific to the lab and must not be considered a reference architecture for production Proxmox environments.

---

## Current Lab Baseline

The current BobHub Proxmox environment has been installed and validated as the virtualization target for the Terraform track.

Validated components:

```text
Proxmox VE host
        ↓
Management access
        ↓
Proxmox Web UI
        ↓
Storage
        ↓
Network bridge
        ↓
Dedicated Terraform identity
        ↓
Proxmox API Token
        ↓
Terraform provider
        ↓
VM provisioning
```

The lab successfully reached the point where Terraform could authenticate to Proxmox and provision a real virtual machine through the Proxmox API.

Environment-specific addresses, credentials and secrets are intentionally excluded from this document.

---

## Proxmox Role in BobHub

Within the BobHub architecture, Proxmox acts as the virtualization platform responsible for hosting the virtual machines provisioned through Terraform.

Current and expected flow:

```text
Developer Workstation
        |
        | Terraform
        v
   Proxmox API
        |
        v
   Proxmox Node
        |
        v
   Virtual Machine
        |
        v
Future Ansible Configuration
        |
        v
Future Application Hosting
```

Terraform is responsible for describing the desired infrastructure state.

Proxmox is responsible for providing the compute, memory, storage and networking resources required by the virtual machine.

---

## Proxmox Host

The current Proxmox host runs as a virtual machine inside VirtualBox.

Current lab architecture:

```text
Host Operating System
        |
        v
     Windows 11
        |
        v
     VirtualBox
        |
        v
     Proxmox VE
```

The Proxmox VM currently uses approximately:

| Resource        | Lab Configuration |
| --------------- | ----------------- |
| Platform        | VirtualBox        |
| Memory          | 6 GB              |
| CPU             | 4 vCPU            |
| Disk            | 80 GB             |
| Disk Allocation | Dynamic           |
| Network Mode    | Bridged Adapter   |

These values are specific to the current lab and may change according to available workstation resources.

The exact host network interface and management addresses must not be included in public documentation.

---

## Management Access

Proxmox management access has been validated through the Proxmox Web UI.

Conceptual access:

```text
Developer Workstation
        |
        | HTTPS
        v
Proxmox Management Interface
        |
        v
Proxmox Web UI / API
```

The management interface uses the standard Proxmox HTTPS service.

Example:

```text
https://PROXMOX_HOST:8006/
```

The real management IP address is intentionally excluded from the repository.

Terraform also uses this HTTPS endpoint to communicate with the Proxmox API.

---

## Package Maintenance

The Proxmox package baseline has been updated and validated.

Package maintenance workflow:

```bash
apt update
apt full-upgrade
```

Pending updates can be checked with:

```bash
apt list --upgradable
```

A reboot may be required when kernel or core Proxmox components are updated.

Package maintenance must be performed carefully because updates may affect:

* Proxmox kernel
* QEMU
* networking
* storage
* virtualization services

The public repository documents the operational procedure but does not contain host-specific package inventories.

---

## Storage Baseline

The current lab has two main Proxmox storage targets available:

```text
local
local-lvm
```

Their current roles are:

| Storage     | Purpose                              |
| ----------- | ------------------------------------ |
| `local`     | ISO images and local Proxmox content |
| `local-lvm` | Virtual machine disks                |

Terraform uses the virtual machine datastore through a variable instead of hardcoding environment-specific storage configuration directly into reusable Terraform code.

Conceptual configuration:

```hcl
proxmox_storage = "LAB_DATASTORE"
```

The current lab validated that Terraform can allocate virtual machine disk space successfully.

---

## Network Baseline

The Proxmox host provides a Linux bridge used by virtual machines.

Current lab bridge:

```text
vmbr0
```

Conceptual topology:

```text
Physical / Lab Network
        |
        v
VirtualBox Bridged Adapter
        |
        v
     Proxmox
        |
        v
      vmbr0
        |
        v
Virtual Machine NIC
```

Terraform connects VM network devices to the Proxmox bridge.

Example Terraform configuration:

```hcl
network_device {
  bridge = var.proxmox_network_bridge
}
```

Environment-specific network addressing must remain outside public documentation.

The public repository must not expose:

* real management addresses
* internal infrastructure IP addresses
* public IP addresses
* sensitive VLAN identifiers
* firewall credentials

---

## Initial VM Standard

The BobHub Terraform implementation uses a small Linux virtual machine as the provisioning baseline.

The original architecture target was:

| Resource          | Standard                          |
| ----------------- | --------------------------------- |
| Platform          | Proxmox                           |
| Operating System  | Ubuntu Server                     |
| CPU               | 2 vCPU                            |
| Memory            | 4 GB                              |
| Disk              | 40 GB                             |
| Network Interface | 1 virtual NIC                     |
| Network           | Proxmox bridge                    |
| Remote Access     | SSH                               |
| Purpose           | BobHub Infrastructure as Code lab |

These values represent an architectural target and may be adjusted according to available lab resources.

The first real Terraform provisioning validation used smaller resource values because the Proxmox environment itself runs nested on a workstation.

The objective is not VM performance.

The objective is validating reproducible infrastructure provisioning.

---

## Compute Assumptions

The initial VM assumes:

* 2 virtual CPUs
* modest memory allocation
* standard virtualized CPU configuration
* no dedicated hardware resources
* no GPU requirements
* no high-availability requirements

The v0.2.0 track focuses on reproducible provisioning rather than performance optimization.

---

## Storage Assumptions

The virtual machine uses:

* one virtual system disk
* Proxmox-managed storage
* environment-specific disk sizing
* Terraform variables for datastore selection

The exact Proxmox datastore should not be unnecessarily hardcoded into reusable configuration.

Terraform variables should be used when environment-specific storage configuration is required.

---

## Network Assumptions

The VM uses a virtual network interface connected to a Proxmox bridge.

Conceptual topology:

```text
Physical / Lab Network
        |
        v
 Proxmox Network Bridge
        |
        v
  Virtual Network Card
        |
        v
     BobHub VM
```

The Terraform configuration allows network-specific values to be supplied through variables.

Sanitized examples should be preferred:

```text
bridge = "LAB_BRIDGE"
network = "LAB_NETWORK"
gateway = "LAB_GATEWAY"
```

---

## Terraform Authentication

Terraform does not use the Proxmox root account.

A dedicated Proxmox user was created for Infrastructure as Code operations.

Current lab identity:

```text
terraform@pve
```

A dedicated role was also created:

```text
Terraform
```

The role follows the principle of least privilege and includes the permissions required for Terraform to inspect and manage VM resources.

Validated permission areas include:

```text
Datastore access
VM allocation
VM audit
CPU configuration
Memory configuration
Disk configuration
Network configuration
CD-ROM configuration
VM options
VM power management
System audit
```

The role is assigned at the appropriate Proxmox scope with propagation enabled.

---

## Terraform API Token

Terraform authenticates using a dedicated Proxmox API Token.

Conceptual token format:

```text
terraform@pve!provider=SECRET
```

The actual token must never be stored in public documentation.

The secret is supplied locally through Terraform environment-specific configuration.

Example local file:

```text
terraform/proxmox/terraform.tfvars
```

This file must remain ignored by Git.

Only a sanitized example should be versioned:

```text
terraform/proxmox/terraform.tfvars.example
```

---

## Terraform Integration Validation

Terraform successfully connected to the Proxmox API using:

```text
Terraform
        ↓
bpg/proxmox provider
        ↓
Proxmox API Token
        ↓
Dedicated Terraform role
        ↓
Proxmox node
        ↓
Storage
        ↓
Network bridge
        ↓
Virtual Machine
```

The first BobHub Terraform-managed VM was successfully created in Proxmox.

This validated:

* provider configuration
* API connectivity
* API Token authentication
* dedicated Terraform permissions
* node selection
* storage access
* network bridge access
* VM allocation
* CPU configuration
* memory configuration
* disk creation
* network interface creation
* ISO attachment
* boot order management
* Terraform state tracking

This represents the primary success criterion for the current Proxmox baseline.

---

## Access Model

There are two different access paths in the BobHub Terraform lab.

### Infrastructure Provisioning

Terraform communicates with the Proxmox API.

```text
Developer Workstation
        |
        | HTTPS / API
        v
     Proxmox
```

Authentication information must not be stored directly in version-controlled Terraform files.

Credentials or API Tokens must be provided through environment-specific configuration or another secure mechanism.

### VM Administration

After provisioning, virtual machines may be administered using SSH when the guest operating system is available.

```text
Administrator
      |
      | SSH
      v
 BobHub Lab VM
```

SSH key authentication should be preferred.

Private SSH keys must never be committed to the repository.

---

## Nested Virtualization Limitation

The current Proxmox instance runs nested inside VirtualBox.

Although nested virtualization support was enabled in VirtualBox, hardware-assisted KVM virtualization was not exposed successfully to the Proxmox guest.

Inside Proxmox:

```text
/dev/kvm
```

was not available.

Attempting to start a nested VM with KVM enabled resulted in:

```text
KVM virtualisation configured, but not available
```

For the current laboratory only, the VM was configured to use QEMU software emulation.

Example:

```bash
qm set <VMID> --kvm 0
```

This is a lab-specific workaround.

It must not be considered a recommended configuration for a real Proxmox host.

A bare-metal Proxmox environment should use hardware-assisted virtualization and KVM.

---

## Guest Operating System Boundary

Terraform successfully provisioned the virtual machine infrastructure.

Guest operating system troubleshooting later encountered limitations caused by the nested architecture.

The validated BobHub boundary is:

```text
Terraform Configuration
        ↓
Proxmox API
        ↓
VM Created
        ↓
Infrastructure Provisioning Validated
```

Guest operating system installation and boot behavior are separate from Terraform infrastructure provisioning.

The nested guest troubleshooting was intentionally stopped after the Terraform objective had already been validated.

A future bare-metal Proxmox environment can be used to validate the complete guest lifecycle.

---

## Repository Security Model

The BobHub repository is public.

Therefore, Terraform and Proxmox documentation must separate reusable configuration from environment-specific information.

### Safe to Version

Examples of information that may be committed:

```text
VM CPU count
VM memory size
VM disk size
Operating system family
Generic architecture diagrams
Terraform variable definitions
Sanitized example values
Generic Proxmox storage roles
Generic network architecture
```

### Must Not Be Versioned

The following information must remain outside Git:

```text
Proxmox API Token secrets
Passwords
SSH private keys
Sensitive Proxmox API endpoints
Real infrastructure IP addresses
Environment-specific terraform.tfvars
Terraform state files
Sensitive infrastructure credentials
```

Screenshots should also be reviewed before being committed because they may expose:

* API Tokens
* host addresses
* usernames
* infrastructure names
* sensitive configuration

---

## Terraform Boundary

BobHub v0.2.0 manages the infrastructure provisioning layer.

```text
Terraform
    |
    +-- VM definition
    +-- CPU
    +-- Memory
    +-- Disk
    +-- Network interface
    +-- Proxmox placement
```

Operating system configuration and application deployment remain separate responsibilities.

Future responsibility:

```text
Terraform
    |
    v
Provision VM
    |
    v
Ansible
    |
    v
Configure Operating System
    |
    v
Docker / Applications
```

This separation keeps Infrastructure as Code and configuration management responsibilities clear.

---

## Future Improvement: Cloud-Init

The initial lab used an Ubuntu installation ISO.

A more automated future implementation should use:

```text
Terraform
        ↓
Proxmox
        ↓
Ubuntu Cloud Image
        ↓
Cloud-Init
        ↓
SSH Key
        ↓
Network Configuration
        ↓
Ready VM
```

This would remove the need for interactive guest operating system installation.

Future improvements may include:

* Ubuntu Cloud Images
* Cloud-Init
* SSH public key injection
* automatic networking
* reusable Proxmox templates
* reusable Terraform modules
* Ansible integration

---

## Architecture Principles

The Proxmox lab follows these principles:

1. **Infrastructure as Code**
   Infrastructure definitions should be reproducible through Terraform.

2. **Least privilege**
   Terraform should use a dedicated identity with only the permissions required for provisioning.

3. **No sensitive data in Git**
   Environment credentials and infrastructure-specific secrets must remain outside the repository.

4. **Reusable configuration**
   VM characteristics should be expressed through variables whenever practical.

5. **Small incremental delivery**
   The first implementation provisions one simple VM successfully before introducing additional complexity.

6. **Clear technology boundaries**
   Terraform provisions infrastructure. Future Ansible automation will configure the operating system.

7. **Lab limitations must be documented**
   Workarounds caused by nested virtualization must not be mistaken for production architecture decisions.

---

## Baseline Validation

Current validated baseline:

* [x] Proxmox VE is installed
* [x] Proxmox packages are updated
* [x] Proxmox Web UI is accessible
* [x] Management access is validated
* [x] Proxmox API access is validated
* [x] Storage is available
* [x] ISO storage is available
* [x] VM disk storage is available
* [x] Network bridge is available
* [x] Dedicated Terraform user exists
* [x] Dedicated Terraform role exists
* [x] Terraform API Token authentication is configured
* [x] Terraform can communicate with the Proxmox API
* [x] Terraform successfully provisioned a VM
* [x] Nested virtualization limitation is documented
* [x] Sensitive infrastructure details are excluded from documentation

---

## Baseline Verification Commands

Useful Proxmox checks:

Check Proxmox version:

```bash
pveversion
```

Check storage:

```bash
pvesm status
```

Check network interfaces and bridges:

```bash
ip link show
```

Check VM configuration:

```bash
qm config <VMID>
```

Check KVM availability:

```bash
ls -l /dev/kvm
```

Check package repositories:

```bash
apt update
```

Check available package updates:

```bash
apt list --upgradable
```

Terraform-specific validation should be performed from the Terraform workstation.

Example:

```powershell
terraform init
terraform fmt
terraform validate
terraform plan -var-file="terraform.tfvars"
```

---

## Success Criteria

The Proxmox lab baseline is considered ready for Terraform when:

* Proxmox VE is installed
* Proxmox packages are updated
* management access is available
* the Web UI is accessible
* storage is available
* a network bridge is available
* Terraform has a dedicated authentication mechanism
* API access has been validated
* Terraform can provision infrastructure
* environment-specific secrets remain outside Git

The current lab satisfies these criteria.

The core Terraform integration was validated by successfully provisioning the first BobHub VM through the Proxmox API.

---

## Related Documentation

```text
docs/operations/terraform-runbook.md
docs/planning/bobhub-v0.2-terraform-proxmox.md
docs/planning/devops-drd-roadmap.md
docs/planning/roadmap.md
```

---

## Related Terraform Files

```text
terraform/proxmox/main.tf
terraform/proxmox/provider.tf
terraform/proxmox/variables.tf
terraform/proxmox/terraform.tfvars.example
```

---

## Version Goal

This document is part of the BobHub Terraform and Infrastructure as Code evolution.

It records both the intended Proxmox architecture and the baseline that was actually validated in the BobHub lab.

The current milestone demonstrates that a Proxmox host can serve as a Terraform target with dedicated authentication, controlled permissions, updated packages, storage, networking and real VM provisioning.

Future iterations can replace the nested lab with a bare-metal Proxmox environment while preserving the same Infrastructure as Code principles.
