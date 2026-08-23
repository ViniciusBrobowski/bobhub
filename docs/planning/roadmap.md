# BobHub Roadmap

## Project Vision

Transform BobHub into a practical Infrastructure and DevOps learning platform focused on real-world scenarios involving:

- Infrastructure
- Networking
- Containers
- Observability
- Infrastructure as Code
- Automation
- Cloud
- Security
- Resilience
- CI/CD
- Configuration Management
- AI-assisted operations

BobHub is developed incrementally.

Each major version should introduce a new technical layer while preserving the knowledge and infrastructure created in previous versions.

The project also serves as a public technical portfolio demonstrating practical experience with infrastructure design, implementation, troubleshooting, documentation, automation, and DevOps practices.

---

# Project Evolution

```text
BobHub v0.1
Infrastructure / Networking / Containers / Observability
                        ↓
BobHub v0.2
Terraform + Proxmox Infrastructure as Code
                        ↓
BobHub v0.3
Multi-Cloud IaC, Security & Resilience
                        ↓
Future
Automation / Ansible / CI/CD / Logging / Kubernetes / AI
```

Current status:

```text
v0.1  ✅ Completed
v0.2  ✅ Completed
v0.3  🚀 Next
```

---

# BobHub v0.1 — Infrastructure and Observability

Status:

```text
✅ Completed
```

BobHub v0.1 established the initial infrastructure and operational foundation of the project.

---

## Infrastructure Foundation

Status:

```text
✅ Completed
```

### Goals

- Deploy the main Linux VPS
- Install Docker
- Deploy Portainer
- Deploy Nginx Proxy Manager
- Deploy Uptime Kuma
- Create the initial service structure

### Results

- Main VPS operational
- Docker operational
- Docker Compose adopted
- Portainer operational
- Nginx Proxy Manager operational
- Uptime Kuma operational
- Base infrastructure prepared for future services

---

## Network and VPN

Status:

```text
✅ Completed
```

### Goals

- Configure WireGuard VPN
- Build a Hub-and-Spoke topology
- Connect the BobHub HQ with remote lab sites
- Validate routing between environments
- Validate SSH connectivity over VPN

### Results

- WireGuard Hub-and-Spoke operational
- HQ configured
- Remote Site A configured
- Remote Site B configured
- VPN handshake validated
- Routing validated
- SSH connectivity validated

Conceptual topology:

```text
                   BobHub VPS / HQ
                          │
                    WireGuard Hub
                          │
              ┌───────────┴───────────┐
              │                       │
           Site A                  Site B
              │                       │
           pfSense                 pfSense
              │                       │
        Local Network            Local Network
```

---

## Documentation and Version Control

Status:

```text
✅ Completed
```

### Goals

- Create the Git repository
- Connect BobHub to GitHub
- Organize repository structure
- Document architecture and operations
- Adopt issue-based development
- Use Pull Requests for changes

### Results

- Git configured
- GitHub repository created
- Repository structure organized
- Technical documentation created
- GitHub Issues adopted
- Pull Request workflow adopted
- Git helpers created

---

## Docker Compose and Service Versioning

Status:

```text
✅ Completed
```

### Goals

- Version Docker-based services
- Organize service definitions in Git
- Maintain reusable Docker Compose configurations
- Keep infrastructure configuration documented

### Results

- Docker Compose files versioned
- Service folders organized under `docker/`
- Observability stack versioned
- Infrastructure configuration stored in Git

---

## Observability

Status:

```text
✅ Completed
```

### Technologies

- Prometheus
- Grafana
- Node Exporter
- Docker Compose

### Goals

- Collect infrastructure metrics
- Monitor the main VPS
- Create Grafana dashboards
- Validate host-level metrics

### Results

- Prometheus operational
- Grafana operational
- Node Exporter operational
- Main VPS metrics available
- Grafana dashboard operational
- Host metrics correctly collected from the VPS

The initial monitoring flow is:

```text
Node Exporter
      ↓
Prometheus
      ↓
Grafana
```

---

## Alerting

Status:

```text
✅ Completed
```

### Technologies

- Prometheus
- Alertmanager
- Discord

### Goals

- Implement infrastructure alerts
- Connect Prometheus to Alertmanager
- Send alert notifications
- Validate firing and resolved events

### Results

- Alertmanager deployed
- Prometheus connected to Alertmanager
- Alert rules configured
- Discord notification integration configured
- Firing notifications validated
- Resolved notifications validated

Alert flow:

```text
Node Exporter
      ↓
Prometheus
      ↓
Alertmanager
      ↓
Discord
```

A real failure scenario was validated by stopping Node Exporter and observing the complete alert lifecycle.

---

## Observability Release

Status:

```text
✅ Completed
```

### Results

- Observability milestone documented
- Monitoring stack validated
- Alerting flow validated
- Technical checkpoint created
- Public project milestone established

---

# BobHub v0.2 — Terraform + Proxmox

Status:

```text
✅ Completed
```

BobHub v0.2 introduced Infrastructure as Code into the project.

The goal was to move from manually prepared infrastructure toward reproducible infrastructure provisioning through Terraform.

---

## Proxmox Lab Foundation

Status:

```text
✅ Completed
```

### Goals

- Create a Proxmox lab environment
- Document the virtualization architecture
- Prepare Proxmox for Terraform
- Validate storage
- Validate networking
- Configure Terraform authentication

### Results

- Proxmox VE installed
- Management access validated
- Storage validated
- Network bridge validated
- Terraform API authentication configured
- Dedicated Terraform identity created
- Least-privilege role implemented

---

## Terraform Project Foundation

Status:

```text
✅ Completed
```

### Goals

- Create the Terraform project structure
- Configure the Proxmox provider
- Define VM variables
- Protect environment-specific values
- Create safe example configuration

### Results

Terraform structure created under:

```text
terraform/
└── proxmox/
```

Implemented:

- `main.tf`
- `variables.tf`
- `outputs.tf`
- `providers.tf`
- `terraform.tfvars.example`
- Terraform documentation

---

## Terraform State Strategy

Status:

```text
✅ Completed
```

### Goals

- Define how Terraform state is handled
- Prevent sensitive state files from reaching Git
- Document state behavior

### Results

Local Terraform state adopted for the first implementation.

Protected files include:

```text
terraform.tfvars
*.tfstate
*.tfstate.backup
.terraform/
```

A remote backend may be introduced in a future BobHub version.

---

## Proxmox VM Resource

Status:

```text
✅ Completed
```

### Goals

- Define a virtual machine using Terraform
- Connect the resource definition to Proxmox
- Validate Terraform planning

### Results

- Proxmox VM resource implemented
- CPU configuration validated
- Memory configuration validated
- Disk configuration validated
- Network bridge integration validated
- Terraform plan successfully generated

---

## First Terraform Provisioning

Status:

```text
✅ Completed
```

### Goal

Validate the complete Infrastructure as Code workflow.

Validated flow:

```text
Terraform
    ↓
Proxmox Provider
    ↓
Proxmox API
    ↓
Node
    ↓
Storage
    ↓
Network Bridge
    ↓
Virtual Machine
```

### Results

- `terraform init` validated
- `terraform validate` validated
- `terraform plan` validated
- `terraform apply` validated
- First VM successfully created through Terraform

This validated the main objective of BobHub v0.2.

---

## Terraform Runbook

Status:

```text
✅ Completed
```

The operational workflow is documented for:

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

The runbook also documents:

- Terraform state considerations
- Sensitive configuration handling
- Operational safety
- Troubleshooting scenarios

---

## Nested Virtualization Limitation

Status:

```text
⚠️ Documented
```

The Proxmox lab runs inside VirtualBox:

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

The guest VM therefore required software emulation.

```bash
qm set 100 --kvm 0
```

Ubuntu guest boot limitations were observed under this architecture.

These limitations do not invalidate the BobHub v0.2 objective because the Terraform-to-Proxmox provisioning workflow was successfully validated.

---

## Git Workflow Improvements

Status:

```text
✅ Completed
```

During the v0.2 development cycle, BobHub also improved its GitHub development workflow.

Implemented helpers include:

```text
start-issue.ps1
git-commit-push.ps1
open-pr.ps1
finish-pr.ps1
```

Current development flow:

```text
GitHub Issue
     ↓
Feature Branch
     ↓
Implementation
     ↓
Commit
     ↓
Pull Request
     ↓
GitHub Actions
     ↓
Merge
     ↓
Issue Finalization
```

---

## BobHub v0.2 Success Criteria

Status:

```text
✅ Achieved
```

BobHub v0.2 is considered complete because:

- Proxmox architecture is documented
- Terraform project structure exists
- Proxmox provider is configured
- VM variables are defined
- Safe example configuration exists
- Terraform state strategy is documented
- Terraform runbook exists
- A VM provisioning workflow was successfully tested
- Sensitive files are excluded from Git
- Proxmox limitations are documented
- A technical checkpoint exists

---

# BobHub v0.3 — Multi-Cloud IaC, Security & Resilience

Status:

```text
🚀 Next
```

BobHub v0.3 will expand the Infrastructure as Code foundation created in v0.2 into public cloud and multi-cloud architecture.

The objective is to build a realistic lab involving multiple cloud providers, security controls, global traffic management, resilience, hybrid networking, disaster recovery, and centralized observability.

---

## Target Cloud Responsibilities

### AWS

Planned role:

```text
Primary Cloud
~70% normal application traffic
```

Expected technologies:

- Terraform
- VPC
- Subnets
- Routing
- Security Groups
- WAF
- Application Load Balancer
- Compute
- Traefik

---

### Oracle Cloud Infrastructure

Planned role:

```text
Active DR Cloud
~30% normal application traffic
```

Expected technologies:

- Terraform
- VCN
- Subnets
- OCI WAF
- OCI Load Balancer
- Compute
- Traefik
- Object Storage

OCI should remain capable of receiving 100% of application traffic during a primary-cloud failure scenario.

---

### Microsoft Azure

Planned role:

```text
Shared Data Layer
```

Expected technologies:

- Terraform
- Azure networking
- PostgreSQL Flexible Server
- Managed database services

The application architecture should remain stateless where practical.

---

## Global DNS and Traffic Management

Planned technologies:

- PowerDNS Authoritative
- DNS delegation
- Weighted DNS
- Health-aware routing
- High availability authoritative DNS

Normal traffic target:

```text
AWS 70%
OCI 30%
```

Failure scenario:

```text
AWS 0%
OCI 100%
```

Recovery should support gradual failback.

Example:

```text
AWS 10 / OCI 90
AWS 30 / OCI 70
AWS 50 / OCI 50
AWS 70 / OCI 30
```

---

## Cloud Security

Planned scope:

- AWS WAF
- OCI WAF
- Security Groups
- Network security rules
- Least-privilege Terraform identities
- Controlled public exposure
- Secret protection
- Security validation tests

The project should validate allowed and blocked HTTP traffic where practical.

---

## Regional Load Balancing

Planned architecture:

```text
Global DNS
    ↓
Cloud WAF
    ↓
Cloud Load Balancer
    ↓
Traefik
    ↓
Applications
```

Cloud load balancers will provide regional availability and target health monitoring.

Traefik will provide application-level routing and middleware.

Global traffic weighting should be performed at a single global layer to avoid conflicting routing decisions.

---

## Hybrid Networking

Planned initial topology:

```text
BobHub Lab
    ↓
pfSense
    ↓
IPsec Site-to-Site VPN
    ↓
AWS
```

Initial goals:

- Terraform-managed AWS VPN resources
- pfSense IPsec configuration
- Static routing
- Connectivity validation

BGP may be evaluated later.

---

## Centralized Observability

The existing BobHub VPS is expected to evolve into the central Observability Hub.

Conceptual architecture:

```text
                    BobHub VPS
                         │
              Central Observability
                         │
       ┌─────────────────┼─────────────────┐
       │                 │                 │
      AWS               OCI              Azure
       │                 │                 │
    Traefik           Traefik          Database
       │                 │
     Apps              Apps
```

Expected components:

- Prometheus
- Grafana
- Alertmanager
- Uptime Kuma
- Loki in a later stage

The observability environment should remain operational while cloud failure scenarios are tested.

---

## Disaster Recovery

One of the main v0.3 objectives will be a controlled DR test.

Expected scenario:

```text
AWS 70%
OCI 30%
    ↓
AWS failure
    ↓
AWS 0%
OCI 100%
    ↓
Measure RTO
    ↓
Restore AWS
    ↓
Gradual failback
    ↓
AWS 70%
OCI 30%
```

Terraform state isolation must allow AWS infrastructure to be destroyed without affecting:

- OCI
- Azure
- Global DNS
- Observability

---

## Terraform Multi-Cloud Structure

Expected structure:

```text
terraform/
├── proxmox/
│   └── ...
│
└── multicloud/
    ├── aws-primary/
    ├── oci-dr/
    ├── azure-data/
    └── global/
```

Each major environment should use an independent Terraform state.

---

## FinOps

Cost control will be treated as part of the architecture.

Planned practices:

- Cloud budgets
- Billing alerts
- Resource tagging
- Free-tier usage where practical
- Ephemeral AWS lab resources
- Terraform-based cleanup
- Avoid unnecessary paid network resources
- Document service cost models before deployment

No paid cloud service should be introduced without understanding how it is billed and how it can be removed.

---

## Expected v0.3 Validation

The version should eventually demonstrate:

- Multi-cloud Terraform
- AWS infrastructure
- OCI infrastructure
- Azure managed database
- Global DNS
- Weighted traffic
- Health-based failover
- WAF
- Regional load balancing
- Traefik
- Hybrid IPsec VPN
- Centralized observability
- Cloud failure simulation
- Disaster recovery
- Failback
- RTO measurement
- RPO discussion
- FinOps practices

---

# Future Tracks

The following tracks remain planned after the current Infrastructure as Code evolution.

Their final order may change based on practical priorities.

---

## Configuration Management

Status:

```text
📅 Planned
```

Primary technology:

```text
Ansible
```

Possible goals:

- Linux baseline automation
- Docker installation
- Node Exporter installation
- Server configuration
- Application preparation
- Cloud instance configuration

---

## Centralized Logging

Status:

```text
📅 Planned
```

Possible technologies:

- Loki
- Grafana
- Log collectors

Possible goals:

- Centralize VPS logs
- Collect cloud workload logs
- Search logs through Grafana
- Correlate metrics and logs

---

## CI/CD

Status:

```text
📅 Planned
```

Primary technology:

```text
GitHub Actions
```

Possible goals:

- Terraform validation
- Docker validation
- Documentation validation
- Automated deployments
- Infrastructure deployment workflows
- Automatic synchronization with BobHub hosts

---

## Automation

Status:

```text
📅 Planned
```

Possible technologies:

- PowerShell
- Bash
- Python
- n8n
- GitHub Actions

Possible goals:

- Automate repetitive infrastructure operations
- Improve repository workflows
- Automate environment validation
- Automate operational reports

---

## Kubernetes

Status:

```text
📅 Future
```

Kubernetes is intentionally not part of the current project phase.

The project should first consolidate:

- Infrastructure as Code
- Cloud networking
- Security
- Load balancing
- Resilience
- Automation
- CI/CD

before introducing container orchestration complexity.

---

## AI-assisted Operations

Status:

```text
📅 Future
```

Possible technologies:

- Local LLMs
- OpenWebUI
- Ollama
- ChatOps
- Automation integrations

Possible goals:

- Infrastructure queries
- Operational assistance
- Alert analysis
- Documentation assistance
- ChatOps experiments

---

# Long-Term Goal

BobHub should evolve into a complete personal DevOps lab combining:

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
Security
      ↓
Resilience
      ↓
Automation
      ↓
Configuration Management
      ↓
CI/CD
      ↓
Centralized Logging
      ↓
Container Orchestration
      ↓
AI-assisted Operations
```

The long-term objective is not simply to deploy technologies.

The goal is to understand how they interact, how they fail, how they are monitored, how they can be automated, and how they can be rebuilt reproducibly.

Every major implementation should generate practical evidence through code, documentation, tests, Git history, checkpoints, and releases.