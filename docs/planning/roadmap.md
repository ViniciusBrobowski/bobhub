# Roadmap

## Project Vision

Transform BobHub into a practical learning platform focused on Infrastructure, Networking, Observability, Automation, DevOps, and AI-assisted operations.

The main goal is to use the environment to develop hands-on technical skills based on real-world enterprise scenarios.

BobHub is also used as a technical portfolio to demonstrate practical experience with infrastructure operations, documentation, version control, monitoring, and progressive DevOps adoption.

---

# Phase 1 — Infrastructure Foundation

Status: ✅ Completed

## Goals

* Deploy the main Linux VPS
* Install and configure Docker
* Deploy Portainer
* Deploy Nginx Proxy Manager
* Deploy Uptime Kuma
* Prepare the base structure for future services

## Results

* Main VPS operational
* Docker operational
* Portainer operational
* Nginx Proxy Manager operational
* Uptime Kuma operational
* Base infrastructure ready for new services

---

# Phase 2 — Network and VPN

Status: ✅ Completed

## Goals

* Configure WireGuard VPN
* Build a Hub-and-Spoke topology
* Connect HQ, Site A, and Site B
* Validate routing between environments
* Validate SSH access between environments

## Results

* HQ operational
* Site A configured
* Site B configured
* WireGuard Hub-and-Spoke VPN operational
* VPN handshake working
* Routing working
* SSH access working

---

# Phase 3 — Documentation and Version Control

Status: ✅ Completed

## Goals

* Create the Git repository
* Connect the project to GitHub
* Organize the repository structure
* Document the architecture
* Document the network
* Document the monitoring stack
* Maintain a roadmap

## Deliverables

* README.md
* docs/architecture.md
* docs/network.md
* docs/operations/monitoring.md
* docs/planning/roadmap.md
* Organized repository structure
* GitHub repository connected
* Initial documentation versioned

## Results

* Git configured
* GitHub SSH access configured
* Repository created
* Project structure organized
* Documentation started
* README improved for portfolio purposes

---

# Phase 4 — Docker Compose and Service Versioning

Status: ✅ Completed

## Goals

* Version Docker-based services
* Organize service definitions in Git
* Keep infrastructure configuration documented
* Create a reusable structure for future services

## Technologies

* Docker
* Docker Compose
* Git
* GitHub

## Deliverables

* Docker Compose files
* Observability stack definition
* Service folders under `docker/`
* Versioned infrastructure configuration

## Results

* Docker Compose structure created
* Observability stack versioned
* Repository prepared for future infrastructure components

---

# Phase 5 — Observability v1

Status: ✅ Completed

## Goals

* Deploy Prometheus
* Deploy Grafana
* Deploy Node Exporter
* Collect real metrics from the main VPS
* Import a Grafana dashboard
* Validate host-level metrics

## Technologies

* Prometheus
* Grafana
* Node Exporter
* Docker Compose

## Deliverables

* Prometheus configuration
* Grafana service
* Node Exporter service
* Dashboard `1860 - Node Exporter Full`
* Main VPS metrics

## Results

* Prometheus operational
* Grafana operational
* Node Exporter operational
* Dashboard imported and working
* Main VPS host metrics visible in Grafana
* Node Exporter adjusted to monitor the real host instead of only the container

## Important Implementation Note

Node Exporter was adjusted with:

```yaml
command:
  - '--path.rootfs=/host'

volumes:
  - '/:/host:ro,rslave'
```

This allows the containerized Node Exporter to collect metrics from the real VPS host filesystem.

---

# Phase 6 — Release v1.0-observability

Status: ✅ Completed

## Goals

* Create a project milestone for the first observability version
* Tag the current stable state
* Publish a GitHub release
* Document what was delivered in Observability v1

## Deliverables

* Git tag `v1.0-observability`
* GitHub release `v1.0-observability`
* Release notes
* Updated roadmap

## Expected Results

* First public project milestone created
* Observability v1 documented as a completed phase
* Project better structured as a DevOps portfolio

---

# Phase 7 — Alerting

Status: 📅 Planned

## Goals

* Implement basic infrastructure alerts
* Create alert rules for critical resources
* Validate alert behavior
* Prepare future notification integrations

## Technologies

* Prometheus
* Grafana

## Initial Alert Ideas

* High CPU usage
* High memory usage
* Low disk space
* Host down
* Node Exporter unavailable
* Prometheus target down

## Deliverables

* Basic alert rules
* Alert documentation
* Test evidence
* Updated monitoring documentation

---

# Phase 8 — Remote Host Monitoring

Status: 📅 Planned

## Goals

* Monitor Ubuntu-A
* Monitor Ubuntu-B
* Extend Prometheus targets
* Validate metrics over VPN
* Create visibility for remote sites

## Technologies

* Prometheus
* Grafana
* Node Exporter
* WireGuard

## Deliverables

* Node Exporter on Ubuntu-A
* Node Exporter on Ubuntu-B
* Prometheus scrape configuration for remote hosts
* Grafana dashboard visibility for remote hosts

---

# Phase 9 — Centralized Logs

Status: 📅 Planned

## Goals

* Implement centralized log collection
* Collect logs from the main VPS
* Prepare log collection from remote hosts
* Visualize logs in Grafana

## Technologies

* Loki
* Promtail
* Grafana

## Deliverables

* Loki service
* Promtail service
* Log dashboards
* Basic log queries
* Documentation

---

# Phase 10 — Automation

Status: 📅 Planned

## Goals

* Create operational automation
* Automate repetitive tasks
* Build workflows for infrastructure operations
* Document automation use cases

## Technologies

* n8n
* Scripts

## Deliverables

* Automated workflows
* Operational playbooks
* Infrastructure scripts
* Integration examples

---

# Phase 11 — Configuration Management

Status: 📅 Planned

## Goals

* Automate provisioning
* Standardize server configuration
* Improve repeatability
* Reduce manual setup steps

## Technologies

* Ansible

## Deliverables

* VPS provisioning playbook
* Service deployment playbook
* Node Exporter installation playbook
* Base Linux configuration playbook

---

# Phase 12 — CI/CD

Status: 📅 Planned

## Goals

* Implement automated validation
* Create deployment pipelines
* Practice continuous delivery concepts
* Validate infrastructure files before applying changes

## Technologies

* GitHub Actions

## Deliverables

* GitHub Actions workflows
* Docker Compose validation pipeline
* Documentation validation pipeline
* Basic deployment pipeline

---

# Phase 13 — AI-assisted Operations

Status: 📅 Planned

## Goals

* Explore AI-assisted infrastructure operations
* Deploy an internal assistant
* Test operational queries
* Study ChatOps possibilities

## Technologies

* OpenWebUI
* Ollama
* ChatOps integrations

## Deliverables

* OpenWebUI deployment
* Local AI assistant
* Operational query examples
* ChatOps proof of concept

---

# Long-Term Goal

Build a complete personal DevOps platform combining:

* Infrastructure
* Networking
* VPN
* Observability
* Monitoring
* Logs
* Alerting
* Automation
* Configuration Management
* CI/CD
* Artificial Intelligence

The long-term objective is to develop practical skills applicable to real-world enterprise environments while maintaining a public technical portfolio.
