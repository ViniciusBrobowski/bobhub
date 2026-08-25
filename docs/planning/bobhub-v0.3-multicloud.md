# BobHub v0.3.0 — Multi-Cloud IaC, Security & Resilience

## Status

```text
Planning
```

---

# Objective

BobHub v0.3.0 expands the Infrastructure as Code foundation created in v0.2.0 into a practical multi-cloud architecture.

The version will combine:

- AWS
- Oracle Cloud Infrastructure
- Microsoft Azure
- Terraform
- Cloud networking
- WAF
- Load balancing
- Traefik
- Global DNS
- Hybrid networking
- Centralized observability
- Disaster Recovery
- FinOps

The main objective is not simply to deploy resources in multiple cloud providers.

BobHub v0.3.0 must demonstrate that the infrastructure can be:

```text
Designed
   ↓
Provisioned
   ↓
Observed
   ↓
Secured
   ↓
Intentionally disrupted
   ↓
Recovered
   ↓
Rebuilt
```

---

# Version Architecture

The target architecture is:

```text
                              INTERNET
                                 │
                                 ▼
                         Global DNS / GSLB
                           AWS 70 / OCI 30
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                    ▼                         ▼

                   AWS                       OCI
              Primary Cloud               Active DR
                    │                         │
                   WAF                       WAF
                    │                         │
                   ALB                  Load Balancer
                    │                         │
                Traefik                  Traefik
                    │                         │
             Applications               Applications
                    │                         │
                    └────────────┬────────────┘
                                 │
                                 ▼
                        Azure PostgreSQL
```

Supporting infrastructure:

```text
BobHub VPS
├── Prometheus
├── Grafana
├── Alertmanager
├── Uptime Kuma
└── PowerDNS NS1

OCI
└── PowerDNS NS2

Home Lab
└── pfSense
      │
      └── IPsec Site-to-Site VPN → AWS
```

---

# Cloud Responsibilities

## AWS

Role:

```text
Primary Application Cloud
```

Normal traffic target:

```text
~70%
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
- Demo application
- Site-to-Site VPN

AWS should be disposable and reproducible through Terraform.

---

## Oracle Cloud Infrastructure

Role:

```text
Active Disaster Recovery
```

Normal traffic target:

```text
~30%
```

Expected components:

- VCN
- Subnets
- Route tables
- Security rules
- OCI WAF
- OCI Load Balancer
- Compute
- Traefik
- Demo application
- Object Storage
- PowerDNS NS2

OCI must be able to receive:

```text
100% traffic
```

during AWS failure scenarios.

---

## Microsoft Azure

Role:

```text
Shared Data Layer
```

Expected components:

- Resource Group
- Networking
- PostgreSQL Flexible Server
- Database firewall or equivalent access controls
- TLS connectivity

Both AWS and OCI workloads should be able to consume the same logical database layer.

---

# Application Scope

BobHub v0.3.0 will use a simple stateless demonstration application.

Required endpoints:

```text
/health
/whoami
```

Optional endpoint:

```text
/metrics
```

The application should support visible traffic validation.

Example:

```json
{
  "cloud": "AWS",
  "instance": "aws-app-01"
}
```

or:

```json
{
  "cloud": "OCI",
  "instance": "oci-app-01"
}
```

The application itself is not the main product of v0.3.0.

Its purpose is to validate the infrastructure.

---

# Global Traffic Strategy

Normal state:

```text
AWS 70%
OCI 30%
```

AWS failure:

```text
AWS 0%
OCI 100%
```

Recovery:

```text
AWS 10 / OCI 90
AWS 30 / OCI 70
AWS 50 / OCI 50
AWS 70 / OCI 30
```

The architecture should avoid implementing competing traffic distribution logic at multiple layers.

Global traffic selection should happen at the global DNS layer.

Regional application routing should happen through Traefik.

---

# DNS Scope

The preferred architecture is:

```text
Primary Domain
     ↓
Cloudflare
     ↓
Delegated Lab Subdomain
     ↓
PowerDNS Authoritative
```

PowerDNS topology:

```text
NS1 → BobHub VPS
NS2 → OCI
```

The objective is to experiment with:

- Authoritative DNS
- Delegation
- Weighted responses
- Availability-based routing
- DNS resilience

The primary public domain should remain isolated from lab DNS experiments.

---

# Regional Security and Ingress

Each application cloud should use the following model:

```text
Internet
   ↓
WAF
   ↓
Managed Load Balancer
   ↓
Traefik
   ↓
Application
```

Responsibilities must remain separated.

## WAF

Responsible for:

- HTTP security
- Managed security rules
- Request filtering
- Basic SQL injection protection
- Basic XSS protection
- Rate limiting where practical
- Security logs

## Managed Load Balancer

Responsible for:

- Regional ingress
- Target health
- Application availability
- Distribution between regional targets

## Traefik

Responsible for:

- Layer 7 application routing
- Host routing
- Path routing
- Middleware
- Service discovery

Traefik is not the authoritative DNS service.

---

# Hybrid Networking Scope

Initial hybrid networking:

```text
Home Lab
   ↓
pfSense
   ↓
IPsec Site-to-Site VPN
   ↓
AWS
```

This phase should validate:

- Tunnel configuration
- Routing
- Security rules
- Connectivity testing
- Troubleshooting

Cross-cloud private networking between AWS, OCI, and Azure is not required for the first implementation.

---

# Central Observability

The existing BobHub VPS remains independent from the cloud application failure domains.

Expected monitoring stack:

```text
Prometheus
Grafana
Alertmanager
Uptime Kuma
```

Possible future addition:

```text
Loki
```

The monitoring environment should remain available during Disaster Recovery testing.

---

# Terraform Scope

Terraform will manage the public cloud infrastructure.

Expected structure:

```text
terraform/
├── proxmox/
│   └── v0.2 implementation
│
└── multicloud/
    ├── aws-primary/
    ├── oci-dr/
    ├── azure-data/
    └── global/
```

---

# Terraform State Strategy

Each infrastructure responsibility must maintain an independent Terraform state.

```text
aws-primary
    ↓
AWS lifecycle

oci-dr
    ↓
OCI lifecycle

azure-data
    ↓
Azure lifecycle

global
    ↓
Global infrastructure lifecycle
```

This design allows cloud-specific failure and recovery testing.

A destroy operation against AWS must not affect:

- OCI
- Azure
- Global DNS
- BobHub VPS
- Observability

---

# Security Requirements

BobHub v0.3.0 must practice:

- Least privilege
- Dedicated Terraform identities
- Controlled public exposure
- WAF
- Network security rules
- TLS
- Secret hygiene
- Sanitized examples
- No credentials committed to Git
- No Terraform state committed to Git

Sensitive values include:

```text
Cloud API credentials
OCI private keys
Database passwords
SSH private keys
PowerDNS secrets
Terraform state
Real tfvars
Tokens
```

---

# FinOps Requirements

Cloud cost is part of the technical design.

Every major resource must be evaluated for:

```text
Purpose
Cost
Billing model
Required lifetime
Cleanup process
```

BobHub v0.3.0 should use:

- Cloud budgets
- Billing alerts
- Resource tags
- Free tiers where practical
- Cloud credits where available
- Disposable resources
- Terraform cleanup
- Cost documentation

Managed NAT gateways and other fixed-cost resources should not be introduced without explicit justification.

---

# Disaster Recovery Scope

The final resilience test should simulate loss of the AWS application environment.

Initial state:

```text
AWS 70
OCI 30
```

Failure:

```text
terraform destroy AWS
        ↓
AWS unavailable
        ↓
Global traffic shifts
        ↓
OCI receives application traffic
        ↓
Alerts generated
        ↓
RTO measured
```

Recovery:

```text
terraform apply AWS
        ↓
AWS rebuilt
        ↓
Health validated
        ↓
Gradual failback
        ↓
AWS 70
OCI 30
```

---

# RTO and RPO

## RTO

BobHub will measure observed Recovery Time Objective during the DR exercise.

```text
Failure starts
      ↓
Service available through OCI
      ↓
Observed recovery time
```

## RPO

BobHub will document Recovery Point Objective considerations around the shared Azure PostgreSQL data layer.

The project must not claim zero data loss without validation.

---

# Version Deliverables

BobHub v0.3.0 should produce:

- Multi-cloud architecture documentation
- Network and CIDR design
- Terraform state architecture
- FinOps baseline
- AWS Terraform implementation
- OCI Terraform implementation
- Azure Terraform implementation
- Demo application
- WAF configurations
- Regional Load Balancers
- Traefik configuration
- PowerDNS implementation
- Hybrid VPN documentation
- Observability integration
- Security validation
- Traffic distribution validation
- Disaster Recovery test
- RTO result
- RPO analysis
- Recovery and failback test
- Operational runbooks
- Technical checkpoint
- GitHub release

---

# Out of Scope

BobHub v0.3.0 does not require:

- Kubernetes
- Service Mesh
- Production SLA
- Production multi-region database architecture
- Cross-cloud BGP
- Full private connectivity between every provider
- Enterprise secrets platform
- Production-grade zero-downtime guarantees
- Full CI/CD platform implementation
- Ansible configuration management

These remain possible future tracks.

---

# Planned Implementation Sequence

```text
01 — Architecture and Scope
02 — Network and CIDR Design
03 — Terraform State Architecture
04 — FinOps Guardrails
05 — Cloud Credentials and Providers
06 — AWS Network Foundation
07 — AWS Security / WAF / Load Balancer
08 — AWS Application Runtime
09 — OCI Network Foundation
10 — OCI Security / WAF / Load Balancer
11 — OCI Application Runtime
12 — Azure PostgreSQL
13 — Demo Application
14 — Traefik
15 — PowerDNS
16 — Weighted Global Traffic
17 — Hybrid pfSense ↔ AWS VPN
18 — Central Observability
19 — Security Validation
20 — Regional Failure Tests
21 — AWS Disaster Recovery Test
22 — RTO / RPO Documentation
23 — AWS Recovery and Failback
24 — Final Documentation
25 — BobHub v0.3.0 Release
```

The exact issue sequence may be adjusted during implementation.

---

# Success Criteria

BobHub v0.3.0 is considered complete when:

- [ ] Multi-cloud architecture is documented
- [ ] Network and CIDR strategy is documented
- [ ] Terraform states are isolated
- [ ] AWS infrastructure is provisioned with Terraform
- [ ] OCI infrastructure is provisioned with Terraform
- [ ] Azure PostgreSQL is provisioned
- [ ] Application runs in AWS
- [ ] Application runs in OCI
- [ ] WAF is implemented and tested
- [ ] Regional load balancing is implemented
- [ ] Traefik is implemented
- [ ] Global DNS is implemented
- [ ] Normal traffic distribution is validated
- [ ] AWS failure redirects service to OCI
- [ ] Hybrid IPsec VPN is validated
- [ ] Central observability monitors the environment
- [ ] Security validation is documented
- [ ] FinOps controls are implemented
- [ ] AWS infrastructure can be destroyed independently
- [ ] AWS infrastructure can be rebuilt with Terraform
- [ ] RTO is measured
- [ ] RPO is discussed and documented
- [ ] Gradual failback is validated
- [ ] Technical checkpoint is created
- [ ] GitHub Release v0.3.0 is published

---

# Version Completion Definition

BobHub v0.3.0 is not considered complete simply because all cloud resources exist.

The version is complete when the project demonstrates:

```text
Provision
   +
Secure
   +
Observe
   +
Fail
   +
Recover
   +
Rebuild
```

using reproducible infrastructure definitions.

---

# Next Step

After this architecture and planning baseline is approved, the next implementation issue should define:

```text
BobHub v0.3.0
Network and CIDR Design
```

No public cloud infrastructure should be provisioned before the initial network addressing strategy is documented.