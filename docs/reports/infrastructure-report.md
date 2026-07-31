# BobHub Infrastructure Report

## Objective

This document provides a high-level overview of the current BobHub infrastructure.

The goal is to summarize the environment, services, observability stack, automation scripts, current limitations and next steps without exposing sensitive infrastructure details.

BobHub is a practical DevOps and Infrastructure lab used to validate technical knowledge through small, incremental and documented deliveries.

---

## Current Environment

BobHub currently runs as a self-hosted infrastructure lab using a Linux server with Docker-based services.

The environment is intentionally simple and focused on practical learning, operational visibility and automation.

Sensitive infrastructure details such as public IP addresses, hostnames, secrets, tokens and private network information are not documented in this report.

---

## Main Components

The current BobHub environment includes the following components:

| Component | Purpose |
|---|---|
| Docker | Container runtime used to run the lab services |
| Docker Compose | Service orchestration for the local stack |
| Prometheus | Metrics collection and alert rule evaluation |
| Grafana | Metrics visualization |
| Node Exporter | Host metrics exporter |
| Alertmanager | Alert routing and notification management |
| Discord Webhook | Notification channel for lab alerts |
| BobHub CLI | Local command-line helper for operational tasks |
| GitHub Issues | Task tracking and sprint organization |
| GitHub Projects | Kanban board for delivery workflow |

---

## Observability Stack

The observability stack is one of the main technical deliveries of the current BobHub version.

Current flow:

```text
Node Exporter
↓
Prometheus
↓
Alertmanager
↓
Discord
```

The stack allows BobHub to collect host-level metrics, evaluate alert rules and send notifications when monitored components become unavailable.

---

## Services and Ports

The main services exposed by the current lab are:

| Service | Default Port | Purpose |
|---|---:|---|
| Grafana | 3000 | Dashboard and metrics visualization |
| Prometheus | 9090 | Metrics collection and alert rule evaluation |
| Node Exporter | 9100 | Host metrics exporter |
| Alertmanager | 9093 | Alert routing and notification management |

This table documents the expected service ports only. It does not expose public access details.

---

## Alerting

BobHub currently has a basic alerting flow configured and validated.

Implemented alerting capabilities:

- Prometheus alert rule validation
- Alertmanager configuration validation
- Alert delivery through Discord
- Firing alert notification
- Resolved alert notification

The first validated alert was related to Node Exporter availability.

This confirms that the lab is capable of detecting service failure and sending operational notifications.

---

## Automation

BobHub includes automation scripts to reduce repetitive operational tasks and improve consistency.

Current automation areas:

| Area | Description |
|---|---|
| Git helper | Helps create commits and link work to GitHub issues |
| Issue importer | Imports GitHub issues from YAML templates |
| Observability scripts | Start, stop, restart and validate the observability stack |
| Inventory generator | Generates a local infrastructure inventory |
| BobHub CLI | Provides a menu-based interface for common operations |

The generated inventory file is intentionally ignored by Git because it may contain real infrastructure information.

---

## Documentation

Current documentation includes:

| Document | Purpose |
|---|---|
| BobHub CLI documentation | Explains how to use the BobHub CLI |
| DevOps DRD roadmap | Maps DevOps requirements to practical BobHub labs |
| Observability checkpoint | Documents the observability and alerting implementation |
| Infrastructure report | Provides a sanitized overview of the current environment |

---

## Security Considerations

During the infrastructure inventory implementation, it was identified that generated files may expose sensitive or semi-sensitive information, such as:

- Public IP addresses
- Hostnames
- Network details
- Container names
- Runtime environment details

As a result, the generated inventory file is not versioned in Git.

Current approach:

```text
scripts/inventory/generate-inventory.sh  → versioned
docs/inventory.md                        → generated locally and ignored
```

This improves the project security posture and keeps the repository safer for public or portfolio usage.

---

## Current Limitations

The current BobHub environment still has some intentional limitations:

- Single-server lab environment
- Manual infrastructure provisioning
- No Ansible automation yet
- No Terraform provisioning yet
- No CI/CD pipeline validation yet
- No automated security scan before commit or push
- Basic alert rules only
- No production-grade high availability

These limitations are expected for the current project stage.

---

## Next Steps

Recommended next steps for BobHub:

1. Document the observability runbook
2. Create a GitHub release helper
3. Publish the first stable project release
4. Add Ansible for configuration management
5. Add Terraform for infrastructure provisioning
6. Add CI/CD validation for scripts and configuration files
7. Add basic security checks before publishing changes

---

## Version Goal

This report is part of the BobHub v0.1 foundation.

The goal of this version is to prove that the project has:

- Organized task management
- Docker-based infrastructure
- Functional observability
- Alerting flow
- Operational automation
- Basic infrastructure documentation
- Security awareness around generated files

BobHub v0.1 represents the foundation for future DevOps, Infrastructure as Code and Platform Engineering studies.