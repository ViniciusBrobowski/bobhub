# BobHub

BobHub is a personal Infrastructure and DevOps lab created to practice, validate, document, and demonstrate real-world infrastructure engineering skills.

The project evolves incrementally through practical implementations involving networking, containers, observability, automation, Infrastructure as Code, cloud platforms, security, resilience, and DevOps workflows.

The main goal is to build hands-on experience while maintaining a public technical portfolio that documents not only successful implementations, but also technical decisions, limitations, troubleshooting, and lessons learned.

> The main README is maintained in English for portfolio purposes. Detailed technical documentation may use English or Portuguese depending on the context of the lab.

---

## Project Evolution

BobHub is developed through incremental versions.

```text
BobHub v0.1
Infrastructure / Networking / Containers / Observability
                        ↓
BobHub v0.2
Terraform + Proxmox Infrastructure as Code
                        ↓
BobHub v0.3
Multi-Cloud IaC, Security & Resilience
```

Current status:

```text
v0.1  ✅ Completed
v0.2  ✅ Completed
v0.3  🚀 Next
```

---

## Project Goals

BobHub exists to develop practical experience in:

- Linux
- Networking
- VPN
- Docker
- Docker Compose
- Observability
- Monitoring
- Alerting
- Automation
- Git
- GitHub
- CI/CD
- Infrastructure as Code
- Terraform
- Virtualization
- Cloud infrastructure
- Infrastructure security
- Disaster recovery
- Configuration management
- DevOps operations

The project also works as:

- A personal study lab
- A testing environment
- A technical portfolio
- A platform for infrastructure experiments
- A foundation for future DevOps implementations

---

# Current Architecture

BobHub currently combines a persistent VPS environment with local infrastructure labs.

The main VPS acts as the central operational node of the project.

```text
                         BobHub

              ┌─────────────────────────┐
              │      Main VPS / HQ      │
              │                         │
              │ Docker                  │
              │ WireGuard               │
              │ Prometheus              │
              │ Grafana                 │
              │ Alertmanager            │
              │ Node Exporter           │
              │ Uptime Kuma             │
              │ Portainer               │
              │ Nginx Proxy Manager     │
              └────────────┬────────────┘
                           │
                    WireGuard VPN
                           │
              ┌────────────┴────────────┐
              │                         │
         Remote Site A             Remote Site B
              │                         │
           pfSense                   pfSense
              │                         │
         Linux hosts               Linux hosts


                    Local IaC Lab

              Windows Workstation
                       ↓
                  VirtualBox
                       ↓
                  Proxmox VE
                       ↓
              Terraform Provider
                       ↓
                Proxmox API
                       ↓
                 Virtual Machines
```

The VPS remains the persistent core of BobHub while local and cloud environments can be created, tested, destroyed, and rebuilt independently.

---

# Main VPS / HQ

The main VPS is the central operational node of BobHub.

Currently deployed or configured components include:

- Docker
- Docker Compose
- Portainer
- Nginx Proxy Manager
- Uptime Kuma
- WireGuard
- Prometheus
- Grafana
- Node Exporter
- Alertmanager

The VPS is also the foundation for the future BobHub centralized observability platform.

---

# Network and VPN

BobHub uses WireGuard with a Hub-and-Spoke topology.

Conceptual topology:

```text
                     Main VPS / HQ
                           │
                     WireGuard Hub
                           │
             ┌─────────────┴─────────────┐
             │                           │
          Site A                      Site B
             │                           │
          pfSense                     pfSense
             │                           │
        Local Network               Local Network
```

The environment has validated:

- WireGuard connectivity
- Hub-and-Spoke topology
- VPN handshakes
- Routing between environments
- SSH connectivity through the VPN

Remote lab environments are normally powered on only when required.

---

# Observability

BobHub includes a functional infrastructure monitoring stack.

Current flow:

```text
Node Exporter
      ↓
Prometheus
      ↓
Grafana
```

The stack currently provides visibility into host-level metrics including:

- CPU usage
- Memory usage
- Disk usage
- Network traffic
- System uptime
- Load average
- Filesystem information

The Grafana dashboard used during the initial implementation is:

```text
1860 - Node Exporter Full
```

---

## Host Metrics from Docker

Node Exporter runs inside Docker but collects metrics from the actual VPS host.

The container uses:

```yaml
command:
  - '--path.rootfs=/host'

volumes:
  - '/:/host:ro,rslave'
```

This allows Node Exporter to expose host metrics instead of container-only metrics.

---

# Alerting

BobHub also includes a working alerting pipeline.

```text
Node Exporter
      ↓
Prometheus
      ↓
Alertmanager
      ↓
Discord
```

The implementation was validated by intentionally stopping Node Exporter.

Expected behavior:

```text
Node Exporter DOWN
        ↓
Prometheus detects target failure
        ↓
Alertmanager receives firing alert
        ↓
Discord notification received
```

After Node Exporter was started again:

```text
Node Exporter UP
        ↓
Prometheus resolves alert
        ↓
Alertmanager receives resolution
        ↓
Discord resolved notification received
```

Both firing and resolved notifications were successfully validated.

Sensitive webhook information is not stored in Git.

---

# BobHub v0.2.0 — Terraform + Proxmox

BobHub v0.2.0 introduced Infrastructure as Code into the project.

The objective was to validate a reproducible VM provisioning workflow using Terraform and the Proxmox API.

Validated flow:

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

The implementation is located under:

```text
terraform/
└── proxmox/
```

---

## Terraform Structure

The current Proxmox Terraform project includes:

```text
terraform/proxmox/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars.example
└── README.md
```

Environment-specific configuration is kept outside version control.

---

## Terraform Provider

BobHub uses the Proxmox Terraform provider to communicate with the Proxmox API.

The implementation separates:

- Provider configuration
- Infrastructure variables
- Environment-specific values
- VM resource definitions
- Terraform state

Credentials are not hardcoded in Terraform configuration.

---

## Terraform Authentication

Terraform uses a dedicated Proxmox API identity instead of administrator credentials.

The lab uses:

```text
terraform@pve
```

with a dedicated API token and a custom least-privilege role.

The purpose of this configuration is to practice infrastructure automation using dedicated identities and restricted permissions.

Real credentials and tokens are never intentionally committed to the repository.

---

## Terraform State

BobHub v0.2.0 currently uses local Terraform state.

Files such as the following are excluded from Git:

```text
terraform.tfvars
*.tfstate
*.tfstate.backup
.terraform/
```

Only safe example configuration is versioned:

```text
terraform.tfvars.example
```

A remote Terraform backend may be evaluated in a future version.

---

## VM Provisioning Validation

The first BobHub VM was successfully provisioned through Terraform.

The test validated the complete integration path:

```text
Terraform Configuration
        ↓
Provider
        ↓
Authentication
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

This confirmed that the Infrastructure as Code workflow was functional.

---

# Nested Virtualization Lab

The Proxmox environment used during BobHub v0.2.0 runs inside VirtualBox.

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

Hardware-assisted KVM virtualization is not available inside the nested Proxmox environment.

The Proxmox host therefore does not expose:

```text
/dev/kvm
```

The guest VM was configured to use software emulation:

```bash
qm set 100 --kvm 0
```

This configuration is suitable for Infrastructure as Code testing but is not intended to represent production virtualization performance.

---

## Ubuntu Guest Limitation

The Ubuntu Server guest encountered boot-related limitations in the nested software-emulation environment.

During installation, the kernel parameter:

```text
noapic
```

was required to work around:

```text
IO-APIC + timer doesn't work!
```

Additional guest boot issues were observed after installation.

These guest operating system issues were documented but were not considered blockers for BobHub v0.2.0 because the main objective of the version was:

```text
Terraform
↓
Proxmox
↓
VM Provisioning
```

That workflow was successfully validated.

---

# Git and GitHub Workflow

BobHub uses a branch-based Git workflow tied to GitHub Issues and Pull Requests.

The project includes PowerShell helpers for common operations.

Examples:

```text
scripts/git/
├── start-issue.ps1
├── git-commit-push.ps1
├── open-pr.ps1
├── finish-pr.ps1
└── create-release.sh
```

Typical workflow:

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
open-pr.ps1
     ↓
Pull Request
     ↓
Merge
     ↓
GitHub Actions
     ↓
Issue Finalization
     ↓
finish-pr.ps1
```

This workflow helps keep infrastructure changes traceable and documented.

---

# GitHub Actions

BobHub currently includes a GitHub Actions validation workflow.

The workflow executes on changes targeting the `main` branch.

Current responsibilities include:

- Bash script syntax validation
- Docker Compose file discovery/validation workflow
- Linked issue finalization after successful changes reach `main`

Future versions may extend GitHub Actions into deployment and Infrastructure as Code validation pipelines.

---

# Repository Structure

The repository is organized by infrastructure function.

```text
bobhub/
│
├── README.md
│
├── .github/
│   └── workflows/
│
├── docs/
│   ├── architecture/
│   ├── checkpoints/
│   ├── operations/
│   ├── planning/
│   └── reports/
│
├── docker/
│   ├── alertmanager/
│   ├── grafana/
│   ├── nginx-proxy-manager/
│   ├── node-exporter/
│   ├── observability/
│   ├── portainer/
│   ├── prometheus/
│   └── uptime-kuma/
│
├── terraform/
│   └── proxmox/
│
├── wireguard/
│
├── diagrams/
│
├── scripts/
│   └── git/
│
└── templates/
```

The structure will continue evolving as new BobHub versions introduce additional platforms.

---

# Technologies Used

Current technologies used or practiced in BobHub include:

### Infrastructure

- Linux
- Proxmox VE
- VirtualBox

### Infrastructure as Code

- Terraform
- Proxmox API

### Containers

- Docker
- Docker Compose
- Portainer

### Networking

- WireGuard
- pfSense
- Routing
- VPN

### Observability

- Prometheus
- Grafana
- Node Exporter
- Alertmanager
- Uptime Kuma

### Reverse Proxy

- Nginx Proxy Manager

### DevOps

- Git
- GitHub
- GitHub Issues
- GitHub Pull Requests
- GitHub Actions
- PowerShell
- Bash

---

# Current Status

## BobHub v0.1 — Infrastructure and Observability

Status:

```text
✅ Completed
```

Implemented:

- Linux VPS
- Docker
- Docker Compose
- Portainer
- Nginx Proxy Manager
- Uptime Kuma
- WireGuard Hub-and-Spoke
- Prometheus
- Grafana
- Node Exporter
- Host monitoring
- Alertmanager
- Prometheus alert rules
- Discord alert notifications
- Infrastructure documentation
- Git and GitHub workflow foundation

---

## BobHub v0.2 — Terraform + Proxmox

Status:

```text
✅ Completed
```

Implemented:

- Proxmox lab architecture
- Proxmox baseline
- Terraform project structure
- Terraform provider configuration
- Dedicated Proxmox Terraform authentication
- Least-privilege role
- Terraform variables
- Safe tfvars example
- Terraform state strategy
- Proxmox VM resource
- Terraform runbook
- First VM provisioning validation
- Git workflow helpers
- Terraform + Proxmox checkpoint

---

# Next Version

## BobHub v0.3.0 — Multi-Cloud IaC, Security & Resilience

The next BobHub version will expand the Infrastructure as Code foundation from the local Proxmox lab into public cloud environments.

The planned architecture will explore:

- AWS
- Oracle Cloud Infrastructure
- Microsoft Azure
- Terraform multi-cloud provisioning
- Isolated Terraform states
- Cloud networking
- WAF
- Load balancing
- Traefik
- PowerDNS
- Active-active architecture
- Weighted traffic distribution
- Health-based failover
- Hybrid networking
- pfSense IPsec VPN
- Shared managed database
- Centralized observability
- Disaster recovery
- RTO and RPO validation
- FinOps and cost controls

Conceptual direction:

```text
                         Internet
                            │
                            ▼
                     Global DNS / GSLB
                            │
               ┌────────────┴────────────┐
               │                         │
              AWS                       OCI
          Primary Cloud             Active DR
               │                         │
              WAF                       WAF
               │                         │
              LB                        LB
               │                         │
            Traefik                  Traefik
               │                         │
           Applications              Applications
               │                         │
               └────────────┬────────────┘
                            │
                            ▼
                    Azure PostgreSQL
```

The existing BobHub VPS is expected to remain outside the cloud environments and evolve into the central observability platform.

---

# Future Areas

After the multi-cloud track, BobHub may continue into:

- Ansible
- Configuration management
- Remote host automation
- Centralized logging
- Loki
- CI/CD
- Automated deployments
- Terraform CI validation
- Infrastructure testing
- Kubernetes
- AI-assisted operations
- ChatOps

The order may change based on practical learning priorities.

---

# Technical Principles

## Practical Learning First

BobHub follows a hands-on learning approach.

The objective is to implement a real scenario, understand how the technology behaves, document the results, and then increase complexity gradually.

---

## Documentation-Driven Evolution

Relevant implementations should generate evidence such as:

- GitHub Issue
- Feature branch
- Git commit
- Pull Request
- Documentation update
- Technical checkpoint
- Release when appropriate

This keeps the evolution of the project traceable.

---

## Infrastructure as Code

Infrastructure that can reasonably be represented as code should progressively move toward reproducible definitions.

BobHub currently uses Terraform for Proxmox and will expand this model into public cloud infrastructure.

---

## Security by Default

Sensitive values should not be committed to Git.

Examples include:

- Passwords
- API tokens
- Private keys
- Terraform state
- Real environment-specific tfvars
- Webhook secrets

The repository should contain only sanitized examples where required.

---

## Cost Awareness

Future cloud environments are intended for laboratory and learning purposes.

Cloud infrastructure should be designed with FinOps principles such as:

- Free-tier usage where practical
- Budgets and billing alerts
- Resource tagging
- Disposable lab environments
- Explicit understanding of paid services
- Terraform-based cleanup

---

# Portfolio Purpose

BobHub is also a technical portfolio.

The project demonstrates practical experience designing, implementing, troubleshooting, documenting, and evolving infrastructure environments.

Instead of presenting only isolated examples, BobHub shows the progression from traditional infrastructure operations toward DevOps practices:

```text
Infrastructure
     ↓
Networking
     ↓
Containers
     ↓
Observability
     ↓
Alerting
     ↓
Infrastructure as Code
     ↓
Multi-Cloud
     ↓
Automation
     ↓
CI/CD
     ↓
Resilience
```

The project intentionally documents both successful implementations and technical limitations encountered during the learning process.

---

# Author

Created and maintained by Vinicius Brobowski.

GitHub:

```text
ViniciusBrobowski
```

Repository:

```text
bobhub
```