# BobHub DevOps DRD Roadmap

## Objective

This document maps the company DevOps DRD requirements to practical BobHub labs.

BobHub is a hands-on Infrastructure and DevOps lab used to build, validate and document real technical knowledge through small and incremental deliveries.

The goal is to use BobHub as practical evidence of DevOps evolution.

---

## Roadmap Strategy

```text
DRD requirement
    ↓
BobHub practical lab
    ↓
Documentation
    ↓
Operational script or automation
    ↓
Evidence of knowledge
```

---

## Current BobHub Evidence

BobHub already has practical evidence in the following areas:

- GitHub repository
- GitHub Project
- Issues and cards workflow
- Git helper script
- BobHub CLI
- CLI documentation
- Docker Compose structure
- Prometheus
- Grafana
- Node Exporter
- Prometheus alert rules
- Health check scripts
- WireGuard VPN
- Nginx Proxy Manager
- Uptime Kuma
- Portainer

---

# Roadmap Tracks

---

## Track 1 — BobHub Core

### Purpose

Build and maintain the base lab structure.

### Current Evidence

- GitHub repository created
- GitHub Project configured
- Issues and cards workflow in use
- Git helper script created
- BobHub CLI created
- CLI documentation created

### DRD Skills Covered

- Docker
- Linux
- Terminal tools
- Basic automation
- Technical documentation

### Next Actions

- Improve README
- Improve architecture documentation
- Keep scripts simple and reusable
- Maintain GitHub Issues as the official workflow

---

## Track 2 — Docker & Containers

### Purpose

Use Docker as the base runtime for BobHub services.

### Current Evidence

- Prometheus running in container
- Grafana running in container
- Node Exporter running in container
- Docker Compose used for observability stack
- Operational scripts created for starting, stopping and validating services

### DRD Skills Covered

- Docker

### Next Actions

- Create Docker operational runbook
- Document Docker Compose structure
- Add container troubleshooting notes
- Standardize container naming and volumes

---

## Track 3 — Linux & Terminal

### Purpose

Strengthen Linux operations and shell scripting skills.

### Current Evidence

- BobHub runs on Linux
- Bash scripts created
- Git automation created
- Observability scripts created
- CLI created in Bash

### DRD Skills Covered

- Linux
- Bash
- Terminal tools

### Next Actions

- Create Linux troubleshooting runbook
- Create Bash scripting standards
- Add script validation patterns
- Document useful operational commands

---

## Track 4 — Networking, Proxy and Web Access

### Purpose

Understand how services are exposed, routed and protected.

### Current Evidence

- WireGuard hub-and-spoke VPN in use
- Nginx Proxy Manager available
- Services exposed through ports
- Monitoring services reachable through web interfaces

### DRD Skills Covered

- Network protocols
- HTTPS
- SSH
- SSL/TLS
- OSI model
- Reverse Proxy
- Firewall
- Load Balancer
- Web Servers

### Next Actions

- Document current network architecture
- Document exposed ports
- Document reverse proxy flow
- Create NGINX reverse proxy lab
- Create NGINX load balancer lab
- Document HTTPS/TLS usage

---

## Track 5 — Observability

### Purpose

Build a complete observability stack for metrics, logs, traces and alerts.

### Current Evidence

- Prometheus deployed
- Grafana deployed
- Node Exporter deployed
- Node Exporter Full dashboard imported
- Prometheus alert rules created
- Prometheus rules validated with promtool
- Health check scripts created

### DRD Skills Covered

- Metrics tools
- Data visualization tools
- Grafana
- Prometheus
- Log aggregation
- Tracing

### Next Actions

- Add Alertmanager
- Configure alert routing
- Configure Discord, Telegram or email alerts
- Add Loki for log aggregation
- Add Promtail for log collection
- Add Tempo or Jaeger for tracing
- Document metrics, logs and traces

---

## Track 6 — High Availability & Resilience

### Purpose

Design and test highly available service architectures.

### Current Evidence

- Monitoring stack exists
- WireGuard connectivity exists
- Reverse proxy foundation exists
- Home lab idea defined

### DRD Skills Covered

- Load Balancer
- Firewall
- Reverse Proxy
- Web Servers
- Observability
- System reliability

### BobHub Home Site Concept

The BobHub Home Site will be a secondary lab node running from a VM at home.

The preferred initial model is to keep the public exposure on the VPS and connect the Home VM through WireGuard.

```text
Internet
   ↓
BobHub VPS
   ├── Reverse Proxy / Load Balancer
   ├── Prometheus / Grafana
   └── WireGuard
          ↓
      Home VM
        ├── Docker
        ├── Node Exporter
        └── Secondary demo app instance
```

### Next Actions

- Document high availability concepts
- Design BobHub Home Site architecture
- Create a simple demo app
- Deploy demo app on VPS
- Deploy demo app on Home VM
- Add load balancer in front of both instances
- Test failure of one instance
- Monitor availability with Uptime Kuma and Prometheus
- Document failover behavior

---

## Track 7 — System Design & Software Architecture

### Purpose

Develop the ability to design, explain and operate application architectures.

### Concepts to Study

- Client/server architecture
- APIs
- Frontend and backend separation
- Stateless applications
- Stateful applications
- Load balancing
- Caching
- Databases
- Queues
- Workers
- Health checks
- Horizontal scaling
- Vertical scaling
- Fault tolerance
- Observability
- Security by design

### BobHub Application Architecture Goal

Create or use a simple application with:

- `/health` endpoint
- `/metrics` endpoint
- Structured logs
- Environment variables
- Optional database connection
- Dockerfile
- Docker Compose deployment

### Next Actions

- Document system design basics
- Document BobHub demo app architecture
- Create architecture diagrams
- Document failure scenarios
- Document scaling options

---

## Track 8 — Infrastructure as Code

### Purpose

Manage infrastructure using code and version control.

### Current Evidence

Not started yet.

### DRD Skills Covered

- Infrastructure as Code
- Terraform or CloudFormation

### Next Actions

- Create Terraform folder structure
- Study Terraform basics
- Create first local Terraform lab
- Use Terraform with Docker provider
- Document Terraform state
- Create Terraform validation script
- Later, provision cloud resources with Terraform

---

## Track 9 — Configuration Management

### Purpose

Automate server configuration and baseline setup.

### Current Evidence

Not started yet.

### DRD Skills Covered

- Configuration Management
- Ansible or Puppet

### Next Actions

- Create Ansible folder structure
- Create inventory
- Create Linux baseline playbook
- Automate Docker installation
- Automate Node Exporter installation
- Document Ansible usage

---

## Track 10 — Cloud Providers

### Purpose

Practice cloud infrastructure concepts and deployment.

### Current Evidence

Cloud experience exists outside BobHub, but is not yet documented as BobHub evidence.

### DRD Skills Covered

- AWS
- Azure
- GCP
- OCI

### Recommended Cloud

OCI can be used first because it is already familiar in the professional environment.

### Next Actions

- Document cloud provider basics
- Create OCI lab notes
- Create network lab with VCN, subnet and security rules
- Provision cloud resources with Terraform
- Document cost control
- Deploy a simple workload to cloud

---

## Track 11 — Kubernetes & Container Orchestration

### Purpose

Learn container orchestration using Kubernetes.

### Current Evidence

Not started yet.

### DRD Skills Covered

- Kubernetes
- Docker Swarm
- Container orchestration

### Next Actions

- Create local Kubernetes lab
- Study Pods, Deployments, Services and Ingress
- Deploy demo app
- Add ConfigMap and Secret
- Add persistent volume
- Add monitoring
- Document Kubernetes basic operations

---

## Track 12 — Secrets Management

### Purpose

Handle secrets safely across applications and infrastructure.

### Current Evidence

Not started yet.

### DRD Skills Covered

- HashiCorp Vault
- AWS Secrets Manager
- Oracle Vault
- Secret management

### Next Actions

- Document secrets management concepts
- Identify what must not be committed
- Study `.env` risks
- Create HashiCorp Vault lab
- Store demo app secrets in Vault
- Document secret rotation

---

## Track 13 — Serverless

### Purpose

Understand event-driven and serverless workloads.

### Current Evidence

Not started yet.

### DRD Skills Covered

- Serverless

### Next Actions

- Document serverless concepts
- Create simple HTTP-triggered function
- Test logs and execution
- Document use cases and limitations

---

## Track 14 — Service Mesh

### Purpose

Understand advanced service-to-service communication.

### Current Evidence

Not started yet.

### DRD Skills Covered

- Istio
- Consul
- Linkerd
- Envoy
- Service Mesh

### Next Actions

- Study service mesh concepts
- Choose one tool, preferably Istio or Linkerd
- Deploy a sample app with service mesh
- Test mTLS
- Test traffic routing
- Document use cases

---

## Track 15 — DevOps Culture, SRE and Reading

### Purpose

Build conceptual foundation beyond tools.

### DRD Items

- Information security policy training
- Manual de DevOps - Gene Kim
- The Phoenix Project
- Site Reliability Engineering - Google
- Accelerate
- Infrastructure as Code - Kief Morris

### How to Apply in BobHub

- Use small issues and incremental delivery
- Automate repetitive tasks
- Create runbooks
- Reduce manual work
- Improve feedback loops
- Create useful alerts
- Document incidents and failure tests
- Use architecture diagrams
- Measure reliability and recovery

### Next Actions

- Create reading notes
- Connect each book or concept to BobHub practices
- Add SRE concepts gradually
- Document RTO, RPO, SLO and SLA basics

---

## Track 16 — Languages and Communication

### Purpose

Improve technical communication.

### DRD Items

- English B1 reading and writing
- English B1 speaking and listening
- Spanish A2/B1
- Portuguese communication

### BobHub Practice

- Keep README in English
- Keep commit messages in English
- Keep GitHub issues in English
- Use Portuguese for personal notes and deeper study
- Later, create a short project summary in Spanish

### Next Actions

- Improve README English
- Write short English explanations for each lab
- Practice explaining BobHub architecture in English
- Create simple presentation notes

---

# Current Priority

The current recommended order is:

1. Finish BobHub core foundation
2. Create this DRD roadmap mapping
3. Continue with Alertmanager
4. Improve networking and proxy documentation
5. Design the High Availability lab
6. Add Loki for logs
7. Start Terraform basics
8. Start Ansible basics
9. Move to Cloud and Kubernetes

---

# Summary

BobHub will be used as a practical evidence-based roadmap for DevOps evolution.

The main idea is:

```text
Study less in isolation.
Build more with purpose.
Document everything.
Turn each lab into evidence.
```