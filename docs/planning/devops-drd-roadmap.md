# BobHub DevOps DRD Roadmap

## Objective

This document maps the company DevOps DRD requirements to practical BobHub labs.

BobHub is a hands-on Infrastructure and DevOps lab used to build, validate, and document real technical knowledge through small and incremental deliveries.

The goal is to use BobHub as practical evidence of DevOps evolution.

The roadmap is evidence-driven.

A topic is considered stronger when BobHub contains practical implementation, validation, documentation, troubleshooting, automation, or failure testing related to that skill.

---

## Roadmap Strategy

```text
DRD Requirement
      ↓
BobHub Practical Lab
      ↓
Implementation
      ↓
Validation
      ↓
Documentation
      ↓
Automation / Runbook
      ↓
Evidence of Knowledge
```

The objective is not only to study technologies individually.

BobHub should demonstrate the ability to combine technologies into realistic infrastructure scenarios.

---

# Current DRD Progress

Current BobHub progress can be summarized as:

| Area | Status |
|---|---|
| Git / GitHub | Strong practical evidence |
| Documentation | Strong practical evidence |
| Docker / Docker Compose | Strong practical evidence |
| Linux / Bash | Practical evidence |
| Networking / VPN | Strong practical evidence |
| Reverse Proxy | Practical evidence |
| Metrics / Monitoring | Strong practical evidence |
| Alerting | Strong practical evidence |
| Terraform / Infrastructure as Code | Strong practical evidence |
| Proxmox Automation | Strong practical evidence |
| High Availability / Resilience | Planned expansion |
| System Design | Planned expansion |
| Cloud Providers | Next major track |
| WAF / Load Balancing | Next major track |
| Hybrid Cloud Networking | Next major track |
| FinOps | Next major track |
| Configuration Management | Planned |
| Centralized Logging | Planned |
| Kubernetes | Future |
| Secrets Management | Future |
| Serverless | Future |
| Service Mesh | Future |

---

# Current BobHub Evidence

BobHub currently contains practical evidence involving:

- Git
- GitHub
- GitHub Issues
- Pull Requests
- GitHub Actions
- Git workflow helpers
- BobHub CLI
- Bash scripting
- PowerShell scripting
- Docker
- Docker Compose
- Portainer
- Nginx Proxy Manager
- WireGuard
- pfSense
- Prometheus
- Grafana
- Node Exporter
- Alertmanager
- Prometheus alert rules
- Discord alert notifications
- Infrastructure health checks
- Infrastructure documentation
- Technical runbooks
- Technical checkpoints
- Terraform
- Terraform state management
- Terraform variables
- Terraform providers
- Proxmox VE
- Proxmox API
- API token authentication
- Least-privilege infrastructure automation
- Virtual machine provisioning through Infrastructure as Code

---

# Roadmap Tracks

---

## Track 1 — BobHub Core

### Status

```text
✅ Strong practical evidence
```

### Purpose

Build and maintain the base lab structure and development workflow.

### Current Evidence

- GitHub repository created
- Repository structure organized
- GitHub Issues used as work items
- Pull Request workflow adopted
- GitHub Actions validation implemented
- Git helper scripts created
- BobHub CLI created
- Technical documentation maintained
- Checkpoint documentation adopted
- Version-based project evolution adopted

### DRD Skills Covered

- Git
- GitHub
- Linux
- Terminal tools
- Basic automation
- Technical documentation
- DevOps workflow

### Current Development Flow

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

### Next Improvements

- Continue improving GitHub Actions
- Introduce automatic infrastructure validation
- Introduce controlled deployment automation
- Improve release automation
- Create PowerShell equivalent for issue importing

---

## Track 2 — Docker & Containers

### Status

```text
✅ Strong practical evidence
```

### Purpose

Use containers as the primary runtime for BobHub services.

### Current Evidence

Containerized services include:

- Prometheus
- Grafana
- Node Exporter
- Alertmanager
- Portainer
- Nginx Proxy Manager
- Uptime Kuma

Docker Compose is used to version service definitions.

### Practical Knowledge Demonstrated

- Container lifecycle
- Docker Compose
- Volumes
- Bind mounts
- Container networking
- Host metric collection
- Container troubleshooting
- Service configuration
- Persistent service definitions

### Important Practical Example

Node Exporter initially collected container-level metrics instead of host metrics.

The configuration was adjusted to expose the host filesystem:

```yaml
command:
  - '--path.rootfs=/host'

volumes:
  - '/:/host:ro,rslave'
```

This allowed Prometheus to collect metrics from the real VPS host.

### DRD Skills Covered

- Docker
- Docker Compose
- Containers
- Linux
- Operational troubleshooting

### Next Improvements

- Create a dedicated Docker operational runbook
- Improve container troubleshooting documentation
- Standardize health checks
- Improve version pinning where appropriate

---

## Track 3 — Linux & Terminal

### Status

```text
🟡 Practical evidence / continuing improvement
```

### Purpose

Strengthen Linux operations and shell automation skills.

### Current Evidence

- BobHub VPS runs Linux
- Bash scripts created
- CLI implemented in Bash
- Git automation implemented
- Monitoring services operated through Linux
- Docker operations performed through Linux
- Networking troubleshooting performed through terminal tools
- Proxmox operated through Linux shell
- Infrastructure validation commands documented

### DRD Skills Covered

- Linux
- Bash
- Terminal tools
- Troubleshooting
- Automation

### Next Improvements

- Linux troubleshooting runbook
- Bash scripting standards
- Standard validation functions
- Service troubleshooting procedures
- Network troubleshooting procedures
- Systemd operational labs

---

## Track 4 — Networking, Proxy and Web Access

### Status

```text
🟡 Strong foundation / major expansion planned
```

### Purpose

Understand how services communicate, are exposed, routed, protected, and made highly available.

### Current Evidence

- WireGuard Hub-and-Spoke VPN
- pfSense lab environments
- Nginx Proxy Manager
- Reverse proxy usage
- SSH connectivity through VPN
- Routing between lab environments
- Service exposure through TCP ports
- HTTP services
- Internal monitoring endpoints

### Current Architecture

```text
                     BobHub VPS
                         │
                    WireGuard
                         │
              ┌──────────┴──────────┐
              │                     │
           Site A                Site B
              │                     │
           pfSense               pfSense
              │                     │
        Local Network          Local Network
```

### DRD Skills Covered

- TCP/IP
- Routing
- VPN
- HTTPS
- SSH
- SSL/TLS
- Reverse Proxy
- Firewall concepts
- Load Balancer concepts
- Web Servers
- Network troubleshooting

### v0.3 Expansion

BobHub v0.3 is expected to significantly expand this track with:

- AWS VPC
- OCI VCN
- Azure networking
- Public and private subnets
- Route tables
- Security Groups
- Cloud security rules
- Load balancers
- WAF
- PowerDNS
- IPsec Site-to-Site VPN
- Hybrid networking
- Multi-cloud routing concepts

---

## Track 5 — Observability

### Status

```text
✅ Metrics and alerting implemented
🟡 Logs and tracing still planned
```

### Purpose

Build an observability platform covering metrics, alerts, logs, and eventually tracing.

### Current Evidence

- Prometheus deployed
- Grafana deployed
- Node Exporter deployed
- Node Exporter Full dashboard configured
- Host metrics collected
- Prometheus alert rules configured
- Alertmanager deployed
- Prometheus connected to Alertmanager
- Discord alerts configured
- Firing alerts validated
- Resolved alerts validated
- Prometheus configuration validated with `promtool`
- Alertmanager configuration validated with `amtool`
- Health checks performed

### Current Metrics Flow

```text
Node Exporter
      ↓
Prometheus
      ↓
Grafana
```

### Current Alert Flow

```text
Node Exporter
      ↓
Prometheus
      ↓
Alertmanager
      ↓
Discord
```

### Failure Validation

A real alert scenario was tested by stopping Node Exporter.

```text
Node Exporter DOWN
        ↓
Prometheus detects failure
        ↓
Alertmanager receives firing alert
        ↓
Discord receives notification
```

After recovery:

```text
Node Exporter UP
        ↓
Prometheus resolves alert
        ↓
Alertmanager processes resolution
        ↓
Discord receives resolved notification
```

### DRD Skills Covered

- Metrics
- Monitoring
- Prometheus
- Grafana
- Alerting
- Infrastructure visibility
- Failure detection

### Remaining Areas

- Loki
- Centralized logs
- Log shipping
- Structured application logs
- Tempo or Jaeger
- Distributed tracing

---

## Track 6 — High Availability & Resilience

### Status

```text
🟡 Foundation exists
🚀 Major practical implementation planned for v0.3
```

### Purpose

Design, implement, test, and observe resilient infrastructure.

### Current Evidence

- Monitoring foundation
- Alerting foundation
- VPN connectivity
- Reverse proxy experience
- Infrastructure as Code foundation
- Failure testing experience

### v0.3 Target Architecture

BobHub v0.3 will introduce an active-active multi-cloud lab.

Expected normal traffic:

```text
AWS 70%
OCI 30%
```

Failure scenario:

```text
AWS 0%
OCI 100%
```

Recovery should include controlled failback.

Example:

```text
AWS 10 / OCI 90
AWS 30 / OCI 70
AWS 50 / OCI 50
AWS 70 / OCI 30
```

### Planned Architecture

```text
                         Internet
                            │
                            ▼
                    Global DNS / GSLB
                            │
               ┌────────────┴────────────┐
               │                         │
              AWS                       OCI
          Primary Cloud              Active DR
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

### DRD Skills Covered

- High Availability
- Disaster Recovery
- Load Balancing
- Fault tolerance
- Infrastructure resilience
- Monitoring
- Failover
- Recovery
- RTO
- RPO

### Planned Practical Validation

```text
AWS 70 / OCI 30
        ↓
Destroy AWS environment
        ↓
OCI receives 100%
        ↓
Measure recovery behavior
        ↓
Rebuild AWS using Terraform
        ↓
Gradual failback
        ↓
AWS 70 / OCI 30
```

---

## Track 7 — System Design & Software Architecture

### Status

```text
🟡 Concepts identified
🚀 Practical expansion planned for v0.3
```

### Purpose

Develop the ability to design, explain, deploy, and operate application architectures.

### Concepts

- Client/server architecture
- APIs
- Frontend/backend separation
- Stateless applications
- Stateful services
- Health checks
- Load balancing
- Databases
- Caching
- Queues
- Workers
- Horizontal scaling
- Vertical scaling
- Fault tolerance
- Observability
- Security by design
- Failure domains
- Recovery strategies

### BobHub Demo Application Goal

The multi-cloud architecture should use a simple application containing:

- `/health`
- `/whoami`
- Optional `/metrics`
- Structured logs
- Environment variables
- Dockerfile
- Database connectivity

Example `/whoami` response:

```json
{
  "cloud": "AWS",
  "instance": "app-01"
}
```

This will make traffic distribution and failover behavior observable.

### v0.3 Learning Objective

Understand why infrastructure components exist instead of simply deploying them.

```text
DNS
 ↓
WAF
 ↓
Load Balancer
 ↓
Reverse Proxy
 ↓
Application
 ↓
Database
```

Each layer should have a documented responsibility.

---

## Track 8 — Infrastructure as Code

### Status

```text
✅ Terraform foundation completed
🚀 Multi-cloud expansion next
```

### Purpose

Manage infrastructure using code and version control.

### Current Evidence

BobHub v0.2 successfully introduced Terraform.

Implemented:

- Terraform project structure
- Proxmox provider
- Variables
- Environment-specific tfvars
- Safe tfvars example
- Terraform state strategy
- VM resource definition
- Proxmox API integration
- Dedicated Terraform authentication
- Least-privilege role
- Terraform runbook
- Successful VM provisioning

### Validated Flow

```text
Terraform
    ↓
Proxmox Provider
    ↓
Proxmox API
    ↓
Virtual Machine
```

### Practical Terraform Workflow

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

### DRD Skills Covered

- Infrastructure as Code
- Terraform
- Providers
- Variables
- State
- Resource lifecycle
- API authentication
- Version-controlled infrastructure

### Next Evolution

BobHub v0.3 will introduce:

```text
terraform/
├── proxmox/
│
└── multicloud/
    ├── aws-primary/
    ├── oci-dr/
    ├── azure-data/
    └── global/
```

Terraform states should be isolated between environments.

This will allow individual cloud environments to be destroyed and rebuilt independently.

---

## Track 9 — Configuration Management

### Status

```text
📅 Planned
```

### Purpose

Automate operating system configuration and server baselines.

### Current Evidence

Configuration is still mostly performed manually or through container definitions.

A dedicated configuration management implementation has not yet been introduced.

### DRD Skills Covered

- Configuration Management
- Ansible
- Infrastructure automation

### Planned Labs

- Create Ansible project structure
- Create inventory
- Create Linux baseline role
- Automate Docker installation
- Automate Node Exporter installation
- Configure cloud instances
- Validate idempotency
- Document Ansible workflows

### Expected Future Flow

```text
Terraform
    ↓
Infrastructure Provisioning
    ↓
Ansible
    ↓
Operating System Configuration
    ↓
Application Runtime
```

---

## Track 10 — Cloud Providers

### Status

```text
🚀 Next major BobHub track
```

### Purpose

Practice real cloud infrastructure and multi-cloud architecture.

### Current BobHub Evidence

BobHub Terraform knowledge is currently validated against Proxmox.

Public cloud infrastructure will become a primary BobHub focus in v0.3.

### Planned Providers

- AWS
- Oracle Cloud Infrastructure
- Microsoft Azure

GCP remains relevant to the DRD but is not part of the initial BobHub v0.3 scope.

### Planned Responsibilities

#### AWS

```text
Primary Compute / Network
~70% normal application traffic
```

Expected components:

- VPC
- Subnets
- Route tables
- Internet connectivity
- Security Groups
- WAF
- Application Load Balancer
- Compute
- Traefik

#### OCI

```text
Active DR
~30% normal application traffic
```

Expected components:

- VCN
- Subnets
- Security rules
- OCI WAF
- OCI Load Balancer
- Compute
- Traefik
- Object Storage

#### Azure

```text
Shared Data Layer
```

Expected components:

- Resource Group
- Networking
- PostgreSQL Flexible Server

### DRD Skills Covered

- AWS
- Azure
- OCI
- Cloud networking
- Cloud security
- Cloud architecture
- Infrastructure as Code

---

## Track 11 — Kubernetes & Container Orchestration

### Status

```text
📅 Future
```

### Purpose

Learn container orchestration after consolidating infrastructure fundamentals.

### Current Evidence

Not started.

### DRD Skills Covered

- Kubernetes
- Docker Swarm
- Container orchestration

### Planned Labs

- Local Kubernetes environment
- Pods
- Deployments
- Services
- Ingress
- ConfigMaps
- Secrets
- Persistent volumes
- Monitoring

### Decision

Kubernetes is intentionally postponed until BobHub has stronger practical evidence in:

- Infrastructure as Code
- Cloud
- Networking
- Security
- Load balancing
- Resilience
- CI/CD

---

## Track 12 — Secrets Management

### Status

```text
🟡 Secret hygiene implemented
📅 Dedicated secret platform not started
```

### Purpose

Handle infrastructure and application secrets safely.

### Current Evidence

BobHub already avoids intentionally committing:

- API tokens
- Terraform state
- Real tfvars
- Private keys
- Discord webhook URLs
- Environment-specific credentials

Example files are used where practical.

### DRD Skills Covered

- Secret handling
- Infrastructure security
- Git hygiene

### Future Technologies

- HashiCorp Vault
- AWS Secrets Manager
- OCI Vault
- Azure Key Vault

### Planned Labs

- Identify secret types
- Store application secrets
- Store infrastructure credentials
- Implement secret retrieval
- Test credential rotation
- Document secret lifecycle

---

## Track 13 — Serverless

### Status

```text
📅 Future
```

### Purpose

Understand event-driven and managed compute workloads.

### Current Evidence

Not started.

### DRD Skills Covered

- Serverless
- Event-driven architecture

### Future Labs

- HTTP-triggered function
- Scheduled function
- Cloud logs
- Environment variables
- Event integration
- Cost model comparison

---

## Track 14 — Service Mesh

### Status

```text
📅 Future
```

### Purpose

Understand advanced service-to-service networking and traffic management.

### Current Evidence

Not started.

### DRD Skills Covered

- Istio
- Consul
- Linkerd
- Envoy
- Service Mesh
- mTLS

### Future Labs

- Deploy a sample service architecture
- Introduce a service mesh
- Test mTLS
- Test service routing
- Test observability integration

Service Mesh should only be introduced after Kubernetes and distributed application fundamentals are understood.

---

## Track 15 — DevOps Culture, SRE and Reading

### Status

```text
🟡 Continuously applied
```

### Purpose

Build conceptual foundations beyond individual tools.

### DRD Items

- Information security policy training
- The DevOps Handbook
- The Phoenix Project
- Site Reliability Engineering
- Accelerate
- Infrastructure as Code

### Current BobHub Practices

BobHub already applies concepts aligned with DevOps and SRE:

- Small incremental changes
- Git-based workflow
- Issue-driven work
- Pull Requests
- Infrastructure as Code
- Automation
- Monitoring
- Alerting
- Failure testing
- Runbooks
- Documentation
- Technical checkpoints
- Reproducibility

### Next Evolution

BobHub v0.3 should introduce practical reliability concepts:

- Failure domains
- RTO
- RPO
- Disaster Recovery
- Active-active architecture
- Health-based failover
- Recovery testing
- Cost awareness
- Resilience validation

---

## Track 16 — Languages and Communication

### Status

```text
🟡 Continuously practiced
```

### Purpose

Improve technical communication alongside technical skills.

### DRD Items

- English B1 reading and writing
- English B1 speaking and listening
- Spanish A2/B1
- Portuguese communication

### Current BobHub Practice

- Main README maintained in English
- Git commit messages written in English
- GitHub Issues written in English
- Technical documentation often written in English
- Portuguese used for deeper study and troubleshooting when useful

### Future Improvements

- Architecture explanations in English
- Short project presentations
- Technical interview-style explanations
- Architecture walkthroughs

---

# BobHub Version Mapping to DRD

## BobHub v0.1

Primary evidence:

```text
Linux
Networking
WireGuard
Docker
Docker Compose
Observability
Monitoring
Alerting
Git
GitHub
Documentation
```

Status:

```text
✅ Completed
```

---

## BobHub v0.2

Primary evidence:

```text
Terraform
Infrastructure as Code
Proxmox
API Authentication
Least Privilege
Terraform State
VM Provisioning
Infrastructure Runbooks
Git Workflow Automation
```

Status:

```text
✅ Completed
```

---

## BobHub v0.3

Primary planned evidence:

```text
AWS
OCI
Azure
Terraform Multi-Cloud
Cloud Networking
PowerDNS
WAF
Load Balancing
Traefik
Hybrid IPsec VPN
High Availability
Active-Active Architecture
Disaster Recovery
RTO / RPO
System Design
FinOps
Centralized Observability
```

Status:

```text
🚀 Next
```

---

# Current Priority

The current recommended execution order is:

```text
Finalize BobHub v0.2.0
        ↓
Publish v0.2.0 Release
        ↓
Define BobHub v0.3 Architecture
        ↓
Define Network / CIDR Strategy
        ↓
Define FinOps Controls
        ↓
Define Terraform State Architecture
        ↓
Build AWS Foundation
        ↓
Build OCI Foundation
        ↓
Build Azure Data Layer
        ↓
Implement Global DNS
        ↓
Implement WAF / Load Balancers
        ↓
Implement Traefik
        ↓
Implement Hybrid VPN
        ↓
Centralize Observability
        ↓
Validate 70/30 Traffic
        ↓
Simulate AWS Failure
        ↓
OCI 100%
        ↓
Measure RTO / Discuss RPO
        ↓
Rebuild AWS
        ↓
Gradual Failback
```

Configuration Management with Ansible remains an important future track, but the immediate BobHub evolution is focused on multi-cloud architecture, security, resilience, and Infrastructure as Code.

---

# DRD Learning Philosophy

BobHub follows an evidence-based learning strategy.

```text
Do not only read about Terraform.
Provision infrastructure with Terraform.

Do not only read about monitoring.
Create metrics and alerts.

Do not only read about failure.
Break the environment and observe it.

Do not only read about Disaster Recovery.
Destroy the primary environment and recover it.

Do not only read about cloud costs.
Measure and control them.
```

---

# Summary

BobHub has evolved beyond its original infrastructure and observability foundation.

The project currently demonstrates practical evidence in:

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
```

The next major evolution is:

```text
Multi-Cloud
      ↓
Security
      ↓
Load Balancing
      ↓
Hybrid Networking
      ↓
High Availability
      ↓
Disaster Recovery
      ↓
FinOps
```

Future tracks will then continue toward:

```text
Configuration Management
      ↓
Centralized Logging
      ↓
CI/CD
      ↓
Kubernetes
      ↓
Advanced Platform Engineering
      ↓
AI-assisted Operations
```

The core philosophy remains:

```text
Study with purpose.
Build real scenarios.
Break things safely.
Recover them.
Automate repetitive work.
Document the evidence.
```