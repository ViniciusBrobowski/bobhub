# BobHub v0.3.0 — Multi-Cloud Architecture

## Status

```text
Architecture Definition
```

## Version

```text
BobHub v0.3.0
Multi-Cloud IaC, Security & Resilience
```

---

# Objective

BobHub v0.3.0 expands the Infrastructure as Code foundation created in v0.2.0 into public cloud environments.

The objective is to design, provision, operate, observe, intentionally disrupt, and recover a multi-cloud application architecture using Terraform.

The version focuses on practical experience involving:

- Multi-cloud Infrastructure as Code
- Cloud networking
- Security
- WAF
- Load balancing
- Application routing
- Global traffic management
- Hybrid networking
- High Availability
- Disaster Recovery
- Centralized observability
- Terraform state isolation
- FinOps
- RTO and RPO

The environment is designed as a learning lab and technical portfolio.

It is not intended to represent a production-ready enterprise architecture.

---

# Architecture Principles

BobHub v0.3.0 follows the following principles:

- Infrastructure should be reproducible through Terraform
- Cloud environments must have independent failure domains
- Terraform state must be isolated by infrastructure responsibility
- AWS must be removable without destroying OCI, Azure, DNS, or observability
- The application should remain stateless
- Global and regional traffic responsibilities must be separated
- Security controls must exist at multiple layers
- Observability must remain available during cloud failure tests
- Cloud cost must be considered part of the architecture
- Failure and recovery must be intentionally tested

---

# High-Level Architecture

```text
                              INTERNET
                                 │
                                 ▼
                     Authoritative Global DNS
                    PowerDNS for Lab Subdomain
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                    │                         │
                  AWS                        OCI
              Primary Cloud               Active DR
              ~70% Traffic               ~30% Traffic
                    │                         │
                    ▼                         ▼
                   WAF                       WAF
                    │                         │
                    ▼                         ▼
                   ALB                  OCI Load Balancer
                    │                         │
                    ▼                         ▼
                 Traefik                  Traefik
                    │                         │
                    ▼                         ▼
              Application Pool          Application Pool
                    │                         │
                    └────────────┬────────────┘
                                 │
                                 ▼
                        Azure PostgreSQL


                           BobHub VPS
                               │
                  Central Observability Hub
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
       Prometheus            Grafana           Alertmanager
          │                                         │
          ├──────── AWS /health /metrics            └── Alerts
          └──────── OCI /health /metrics


                            Home Lab
                               │
                            pfSense
                               │
                       IPsec Site-to-Site
                               │
                               ▼
                              AWS
```

---

# Cloud Responsibilities

## AWS — Primary Cloud

AWS acts as the primary application environment.

Normal traffic target:

```text
~70%
```

Responsibilities:

- Primary compute
- Primary cloud networking
- Public application entry point
- WAF
- Application Load Balancer
- Traefik
- Application instances
- Hybrid IPsec connectivity with the BobHub home lab

Conceptual regional flow:

```text
Internet
   ↓
AWS WAF
   ↓
Application Load Balancer
   ↓
Traefik
   ↓
Application Instances
```

AWS is intentionally designed as a disposable infrastructure environment.

The complete AWS application stack should be capable of being destroyed and rebuilt through Terraform.

---

# OCI — Active Disaster Recovery

Oracle Cloud Infrastructure acts as an active Disaster Recovery environment.

Normal traffic target:

```text
~30%
```

OCI remains online during normal operation.

This provides continuous validation that the DR environment is actually capable of serving application traffic.

Responsibilities:

- Secondary compute
- DR networking
- OCI WAF
- OCI Load Balancer
- Traefik
- Application instances
- Backup or archive storage
- Secondary PowerDNS authoritative server

Conceptual regional flow:

```text
Internet
   ↓
OCI WAF
   ↓
OCI Load Balancer
   ↓
Traefik
   ↓
Application Instances
```

OCI capacity must not be conceptually limited to 30%.

The DR environment must be capable of scaling or being expanded to support:

```text
100% application traffic
```

during a primary-cloud failure.

---

# Azure — Shared Data Layer

Microsoft Azure provides the shared relational data layer.

Primary service:

```text
Azure Database for PostgreSQL
```

The application remains stateless whenever practical.

Both AWS and OCI application environments consume the same logical data layer.

Conceptual flow:

```text
AWS Application ─────┐
                     │
                     ▼
              Azure PostgreSQL
                     ▲
                     │
OCI Application ─────┘
```

This architecture intentionally separates application compute failure from the data layer.

---

## Initial Database Connectivity Strategy

Cross-cloud private networking is not required in the first implementation stage.

For the initial lab, Azure PostgreSQL connectivity may use a controlled public endpoint with:

- TLS required
- Database firewall restrictions
- Explicitly authorized source addresses
- Strong credentials
- No database credentials committed to Git

This is a deliberate laboratory trade-off to avoid introducing complex cross-cloud networking before the main architecture has been validated.

Private cross-cloud connectivity may be introduced in a later iteration.

---

# Application Architecture

BobHub v0.3.0 uses a simple demonstration application.

The application should remain stateless.

Required endpoints:

```text
/health
/whoami
```

Optional:

```text
/metrics
```

---

## Health Endpoint

Example:

```text
GET /health
```

Expected response:

```json
{
  "status": "healthy"
}
```

The endpoint will be used by:

- Load balancers
- External monitoring
- Disaster Recovery validation
- Availability tests

---

## WhoAmI Endpoint

Example:

```text
GET /whoami
```

Possible AWS response:

```json
{
  "cloud": "AWS",
  "instance": "aws-app-01"
}
```

Possible OCI response:

```json
{
  "cloud": "OCI",
  "instance": "oci-app-01"
}
```

This endpoint provides visible evidence of traffic distribution.

Repeated requests should make it possible to observe which cloud is serving traffic.

---

# Global Traffic Management

Global cloud selection must happen at a single layer.

BobHub will not simultaneously implement independent 70/30 decisions in DNS and Traefik.

The intended responsibility is:

```text
Global DNS
    ↓
Select Cloud
    ↓
Regional Infrastructure
    ↓
Traefik
    ↓
Select Application Instance
```

---

# DNS Strategy

The primary public BobHub domain should not depend on the experimental DNS implementation.

The preferred architecture is:

```text
Main Domain
Cloudflare DNS
     │
     │ NS delegation
     ▼
Lab Subdomain
PowerDNS Authoritative
```

Example conceptual structure:

```text
example.com
    ↓
Cloudflare

lab.example.com
    ↓
PowerDNS
```

This isolates DNS experiments from the primary public domain.

---

## PowerDNS Architecture

PowerDNS Authoritative is the preferred technology for the lab Global Server Load Balancing experiment.

Initial authoritative DNS topology:

```text
PowerDNS NS1
BobHub VPS

PowerDNS NS2
OCI VM
```

Conceptually:

```text
                   Lab DNS Delegation
                           │
             ┌─────────────┴─────────────┐
             │                           │
             ▼                           ▼
      BobHub VPS                     OCI VM
     PowerDNS NS1                 PowerDNS NS2
```

Two authoritative servers are used to avoid creating a single DNS failure point.

Zone replication and DNS security will be documented during the PowerDNS implementation phase.

---

# Normal Traffic Distribution

Target distribution:

```text
AWS 70%
OCI 30%
```

Conceptual flow:

```text
100 Requests
     │
     ├── ~70 → AWS
     │
     └── ~30 → OCI
```

Exact observed distribution does not need to be mathematically perfect over small request samples.

The objective is to demonstrate controlled weighted distribution.

---

# Failure Traffic Distribution

When AWS is considered unhealthy:

```text
AWS 0%
OCI 100%
```

Conceptual flow:

```text
AWS
DOWN
 │
 ▼
Global Health Detection
 │
 ▼
Remove AWS from traffic
 │
 ▼
OCI receives application traffic
```

---

# Failback Strategy

AWS should not immediately return to 70% after recovery.

Failback should be gradual.

Example:

```text
AWS  0 / OCI 100
        ↓
AWS 10 / OCI 90
        ↓
AWS 30 / OCI 70
        ↓
AWS 50 / OCI 50
        ↓
AWS 70 / OCI 30
```

This provides a practical example of controlled service restoration.

---

# WAF Responsibility

The WAF protects the HTTP application entry point before traffic reaches the regional load balancer.

Conceptual flow:

```text
Internet
   ↓
WAF
   ↓
Load Balancer
```

Planned validation includes:

- Allowed requests
- Blocked requests
- Basic managed rules
- SQL injection test patterns
- XSS test patterns
- Rate limiting where practical
- Logging

The purpose is to understand the WAF request lifecycle rather than simply enable the service.

---

# Regional Load Balancer Responsibility

Managed cloud load balancers provide regional ingress and target health validation.

AWS:

```text
AWS WAF
   ↓
Application Load Balancer
   ↓
Traefik
```

OCI:

```text
OCI WAF
   ↓
OCI Load Balancer
   ↓
Traefik
```

The regional load balancer is responsible for infrastructure-level target availability.

---

# Traefik Responsibility

Traefik is not the authoritative DNS service.

Traefik operates inside each cloud environment.

Responsibilities include:

- Layer 7 routing
- Host routing
- Path routing
- Middleware
- Service discovery
- Application routing

Conceptual responsibility:

```text
Global DNS
    ↓
Cloud Selection
    ↓
WAF
    ↓
Regional Load Balancer
    ↓
Traefik
    ↓
Application
```

---

# Hybrid Networking

The first hybrid cloud connection will connect the existing BobHub home lab to AWS.

Architecture:

```text
BobHub Home Lab
       │
       ▼
    pfSense
       │
       ▼
IPsec Site-to-Site VPN
       │
       ▼
      AWS
```

The initial VPN implementation should validate:

- Tunnel establishment
- Routing
- Security rules
- Connectivity between selected lab networks
- Basic troubleshooting

Cross-cloud private networking between AWS, OCI, and Azure is intentionally outside the initial implementation.

It may be evaluated after the primary architecture is working.

---

# Central Observability

The existing BobHub VPS remains independent from the public cloud application environments.

This is intentional.

If AWS is destroyed during a DR test, monitoring must remain available.

Architecture:

```text
                     BobHub VPS
                         │
              Central Observability
                         │
        ┌────────────────┼────────────────┐
        │                │                │
       AWS              OCI             Azure
```

Current core services:

```text
Prometheus
Grafana
Alertmanager
Uptime Kuma
```

Future extension:

```text
Loki
```

Possible monitored components include:

- Application `/health`
- Application `/metrics`
- AWS application availability
- OCI application availability
- Traefik
- DNS
- Load balancers
- Database availability

---

# Terraform Architecture

BobHub v0.3.0 will not use one Terraform state for the entire multi-cloud environment.

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

## State Boundaries

Each environment must maintain an independent lifecycle.

```text
aws-primary
    ↓
AWS-only state

oci-dr
    ↓
OCI-only state

azure-data
    ↓
Azure-only state

global
    ↓
Global infrastructure state
```

This is required for Disaster Recovery testing.

---

## Isolation Requirement

The following operation:

```bash
terraform destroy
```

inside:

```text
terraform/multicloud/aws-primary/
```

must affect AWS infrastructure only.

It must not destroy:

```text
OCI
Azure
Global DNS
BobHub VPS
Observability
```

This is a core architectural requirement.

---

# Terraform Dependency Strategy

Direct Terraform dependencies between states should be minimized.

Where cross-environment values are required, the project should explicitly document how they are shared.

Possible examples:

- DNS endpoint values
- Application addresses
- Database hostname
- Monitoring targets

The architecture should avoid creating one large Terraform dependency graph across every cloud.

---

# Security Architecture

Security is treated as a cross-cutting concern.

Planned controls include:

```text
Internet
   ↓
WAF
   ↓
Load Balancer
   ↓
Network Security
   ↓
Traefik
   ↓
Application
   ↓
Database Authentication
```

Infrastructure principles:

- Dedicated automation identities
- Least privilege
- No root/admin credentials when unnecessary
- No credentials committed to Git
- Environment-specific Terraform values excluded from version control
- Cloud firewall rules restricted to required traffic
- Database exposure explicitly controlled
- TLS used for application and database communication where practical
- Public endpoints documented

---

# Secret Handling

BobHub v0.3.0 must not intentionally commit:

- AWS credentials
- OCI private keys
- Azure credentials
- Database passwords
- API tokens
- Terraform state
- Real environment-specific tfvars
- PowerDNS secrets
- Private SSH keys

Sanitized examples may be versioned.

Dedicated cloud secret management platforms may be evaluated later.

---

# FinOps

Cost is considered part of the architecture rather than an operational afterthought.

Every major cloud resource should answer:

```text
What does it cost?
How is it billed?
Is it required?
Can it be destroyed?
How do we know it was removed?
```

---

## FinOps Requirements

BobHub v0.3.0 should implement:

- Cloud budgets
- Billing alerts
- Resource tagging
- Free-tier usage where practical
- Initial cloud credits where available
- Disposable lab resources
- Terraform cleanup procedures
- Cost documentation

Expensive always-on infrastructure should be avoided where it does not provide meaningful learning value.

---

## NAT Gateway Strategy

Managed NAT gateways can generate significant lab cost.

They should not be introduced automatically.

Initial architecture should evaluate lower-cost alternatives before deploying managed NAT services.

If NAT Gateway is required for a specific scenario, its cost and purpose must be documented.

---

# Disaster Recovery Scenario

The main resilience test is an intentional AWS failure.

Initial state:

```text
AWS 70%
OCI 30%
```

Test:

```text
AWS Infrastructure
       ↓
terraform destroy
       ↓
AWS unavailable
       ↓
Global health detection
       ↓
OCI serves application traffic
       ↓
Observe alerts
       ↓
Measure RTO
```

Recovery:

```text
terraform apply
       ↓
AWS rebuilt
       ↓
Validate health
       ↓
Gradual failback
       ↓
AWS 70%
OCI 30%
```

---

# RTO

Recovery Time Objective will be measured during the DR experiment.

Measurement concept:

```text
Failure begins
      ↓
Service restored through OCI
      ↓
Elapsed time = observed RTO
```

The lab will record the observed recovery time rather than define an artificial production SLA.

---

# RPO

Recovery Point Objective depends primarily on the shared data architecture.

Because both application environments use the same Azure PostgreSQL data layer, losing AWS compute should not inherently require restoring an independent AWS database.

The practical RPO discussion must still consider:

- Database availability
- Database backup strategy
- Failed in-flight requests
- Application transaction behavior

The project will document observed behavior rather than claim zero data loss without validation.

---

# Failure Domains

BobHub v0.3.0 intentionally separates failure domains.

```text
Failure Domain 1
AWS Application Environment

Failure Domain 2
OCI Application Environment

Failure Domain 3
Azure Data Layer

Failure Domain 4
Global DNS

Failure Domain 5
BobHub Observability VPS
```

This allows failures to be tested independently.

---

# Out of Scope

The initial BobHub v0.3.0 architecture does not require:

- Kubernetes
- Service Mesh
- Full production-grade multi-region architecture
- Cross-cloud BGP
- Full private connectivity between every cloud
- Enterprise secrets management platform
- Production SLA guarantees
- Production database HA across cloud providers
- Full automated CI/CD deployment
- Zero-downtime guarantees

These may be introduced in future BobHub versions or later v0.3 iterations if they provide learning value.

---

# Implementation Order

Expected high-level implementation sequence:

```text
Architecture
    ↓
Network / CIDR Design
    ↓
Terraform State Design
    ↓
FinOps Guardrails
    ↓
Cloud Credentials / Providers
    ↓
AWS Foundation
    ↓
OCI Foundation
    ↓
Azure Data Layer
    ↓
Demo Application
    ↓
Regional WAF / LB
    ↓
Traefik
    ↓
Global DNS
    ↓
Hybrid VPN
    ↓
Central Observability
    ↓
Traffic Validation
    ↓
Security Validation
    ↓
DR Test
    ↓
Recovery / Failback
    ↓
Documentation
```

---

# Success Criteria

BobHub v0.3.0 should eventually demonstrate practical evidence of:

- Terraform across multiple cloud providers
- Independent Terraform states
- AWS networking and compute
- OCI networking and compute
- Azure managed PostgreSQL
- WAF
- Managed load balancing
- Traefik
- Authoritative DNS
- Weighted global traffic
- Health-aware failover
- Hybrid IPsec VPN
- Centralized observability
- Active Disaster Recovery
- Controlled failure testing
- RTO measurement
- RPO analysis
- Cloud security
- FinOps

---

# Architecture Decision Summary

```text
Primary Cloud
AWS

Active DR
OCI

Shared Data Layer
Azure PostgreSQL

Normal Traffic
AWS 70 / OCI 30

Failure Traffic
AWS 0 / OCI 100

Global Traffic Layer
PowerDNS Authoritative

Primary Domain DNS
Cloudflare

Lab DNS
Delegated subdomain to PowerDNS

Regional Security
AWS WAF / OCI WAF

Regional Ingress
AWS ALB / OCI Load Balancer

Application Routing
Traefik

Application Model
Stateless

Hybrid Connectivity
pfSense ↔ AWS IPsec

Central Observability
Existing BobHub VPS

Terraform Strategy
Independent states

Cost Strategy
FinOps-first / disposable lab infrastructure
```

---

# Conclusion

BobHub v0.3.0 evolves the project from local Infrastructure as Code into a distributed infrastructure architecture.

The version intentionally combines:

```text
Infrastructure as Code
        +
Cloud
        +
Networking
        +
Security
        +
Observability
        +
High Availability
        +
Disaster Recovery
        +
FinOps
```

The project should not simply prove that infrastructure can be deployed.

It should prove that the infrastructure can be understood, observed, intentionally broken, recovered, and rebuilt reproducibly.