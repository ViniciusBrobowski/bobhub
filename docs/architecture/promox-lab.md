# BobHub Proxmox Lab Architecture

## Overview

Proxmox is the virtualization layer used by BobHub for the Infrastructure as Code track introduced in BobHub v0.2.0.

Its role is to provide the target infrastructure where Terraform can create and manage virtual machines in a reproducible and documented way.

The goal of this architecture is not to reproduce a production environment, but to provide a controlled lab where infrastructure provisioning concepts can be practiced and validated.

---

## Proxmox Role in BobHub

Within the BobHub architecture, Proxmox acts as the virtualization platform responsible for hosting the virtual machines provisioned through Terraform.

Expected flow:

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

## Initial VM Standard

The first BobHub Terraform implementation will use a small Linux virtual machine as the baseline.

| Resource | Standard |
|---|---|
| Platform | Proxmox |
| Operating System | Ubuntu Server |
| CPU | 2 vCPU |
| Memory | 4 GB |
| Disk | 40 GB |
| Network Interface | 1 virtual NIC |
| Network | Proxmox bridge |
| Remote Access | SSH |
| Purpose | BobHub Infrastructure as Code lab |

These values are the initial standard and may be adjusted according to available lab resources.

The objective is to keep the VM small enough for lab usage while still supporting future configuration-management and container workloads.

---

## Compute Assumptions

The initial VM assumes:

- 2 virtual CPUs
- 4 GB of RAM
- Standard virtualized CPU configuration
- No dedicated hardware resources
- No GPU requirements
- No high-availability requirements

The v0.2.0 track focuses on reproducible provisioning rather than performance optimization.

---

## Storage Assumptions

The initial VM will use:

- One virtual system disk
- 40 GB initial disk size
- Storage provided by the Proxmox environment

The exact Proxmox datastore name must remain environment-specific and must not be hardcoded into public documentation.

Terraform variables should be used when environment-specific storage configuration is required.

---

## Network Assumptions

The VM will use a virtual network interface connected to a Proxmox bridge.

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

The Terraform configuration should allow network-specific values to be supplied through variables.

The public repository must not expose:

- Real management network addresses
- Internal IP addresses
- Public IP addresses
- VLAN identifiers considered sensitive
- Production bridge names
- Firewall credentials

Sanitized examples or generic placeholders should be used instead.

Examples:

```text
bridge = "LAB_BRIDGE"
network = "LAB_NETWORK"
gateway = "LAB_GATEWAY"
```

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

Credentials or API tokens should be provided using environment-specific configuration or another secure mechanism.

### VM Administration

After provisioning, the VM is expected to be administered using SSH.

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
```

### Must Not Be Versioned

The following information must remain outside Git:

```text
Proxmox API tokens
Passwords
SSH private keys
Real Proxmox API endpoints if sensitive
Real infrastructure IP addresses
Environment-specific terraform.tfvars
Terraform state files
Sensitive datastore or network identifiers
```

---

## Terraform Boundary

BobHub v0.2.0 will manage the infrastructure provisioning layer.

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

Operating system configuration and application deployment are intentionally outside this architecture phase.

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

---

## Architecture Principles

The Proxmox lab follows these principles:

1. **Infrastructure as Code**  
   Infrastructure definitions should be reproducible through Terraform.

2. **No sensitive data in Git**  
   Environment credentials and infrastructure-specific secrets must remain outside the repository.

3. **Reusable configuration**  
   VM characteristics should be expressed through variables whenever practical.

4. **Small incremental delivery**  
   The first implementation should provision one simple VM successfully before introducing additional complexity.

5. **Clear technology boundaries**  
   Terraform provisions infrastructure. Future Ansible automation will configure the operating system.

---

## Success Criteria

The Proxmox architecture is considered defined when:

- The role of Proxmox in BobHub is documented
- The initial VM standard is defined
- CPU, memory and disk assumptions are documented
- Network assumptions are documented
- The access model is documented
- Sensitive infrastructure details are excluded
- The architecture provides enough information to begin Terraform implementation