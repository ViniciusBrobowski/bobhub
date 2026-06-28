# BobHub

BobHub is a personal infrastructure and DevOps lab created by Vinicius Brobowski to practice, document, and demonstrate real-world skills in modern infrastructure operations.

The main goal of this project is to support the transition from Infrastructure Analyst to DevOps Engineer through hands-on implementation of technologies commonly used in corporate environments.

This is not just a collection of isolated tools. BobHub is designed as a functional lab platform that combines networking, VPN, containers, observability, automation, documentation, and version control.

> The main README is maintained in English for portfolio purposes. Detailed technical documentation may be written in Portuguese, since this project is also used as a personal study lab.

---

## Project Goals

BobHub was created to build practical experience in:

* Linux
* Networking
* VPN
* Docker
* Docker Compose
* Observability
* Monitoring
* Automation
* Git
* GitHub
* CI/CD
* Infrastructure as Code
* Environment operations

The project also works as:

* A personal study lab
* A testing environment
* A technical portfolio
* A foundation for future DevOps implementations

---

## Current Architecture

The current architecture uses a main VPS as the central point of the environment.

This VPS acts as the HQ of the lab and hosts the main services, including Docker-based applications, monitoring tools, and the WireGuard VPN hub.

The remote sites connect to the HQ through a WireGuard Hub-and-Spoke topology.

```text
                    HQ / Main VPS
                     10.255.255.1
                           |
            +--------------+--------------+
            |                             |
         Site A                        Site B
      10.255.255.2                  10.255.255.3

 LAN: 10.10.40.0/24            LAN: 10.20.40.0/24
```

---

## Main VPS / HQ

The main VPS is the central node of the BobHub environment.

Currently deployed services:

* Docker
* Portainer
* Nginx Proxy Manager
* Uptime Kuma
* WireGuard Hub
* Prometheus
* Grafana
* Node Exporter

VPN address:

```text
10.255.255.1
```

---

## Remote Sites

### Site A

LAN:

```text
10.10.40.0/24
```

Hosts:

```text
pfSense-A     10.10.40.1
Ubuntu-A      10.10.40.100
WireGuard     10.255.255.2
```

Status:

```text
Configured
Usually powered off
Not currently monitored
```

---

### Site B

LAN:

```text
10.20.40.0/24
```

Hosts:

```text
pfSense-B     10.20.40.1
Ubuntu-B      10.20.40.100
WireGuard     10.255.255.3
```

Status:

```text
Configured
Usually powered off
Not currently monitored
```

---

## VPN

BobHub uses WireGuard with a Hub-and-Spoke topology.

Current status:

```text
Operational
Handshake working
Routing working
SSH access working
```

VPN addressing:

```text
HQ      10.255.255.1
Site A  10.255.255.2
Site B  10.255.255.3
```

Topology:

```text
                    HQ
              10.255.255.1
                     |
        +------------+------------+
        |                         |
        |                         |
     Site A                   Site B

VPN: 10.255.255.2       VPN: 10.255.255.3

LAN: 10.10.40.0/24      LAN: 10.20.40.0/24
```

---

## Observability

The first observability stack has been implemented to monitor the main VPS.

Stack:

```text
Node Exporter
      ↓
 Prometheus
      ↓
   Grafana
```

Current status:

```text
Implemented
Working
Versioned
```

---

## Grafana Dashboard

The current Grafana dashboard used for host monitoring is:

```text
1860 - Node Exporter Full
```

This dashboard is used to visualize real metrics from the main VPS, including:

* CPU usage
* Memory usage
* Disk usage
* Network traffic
* System uptime
* Load average
* Filesystem information

---

## Important Node Exporter Fix

During the initial observability setup, Node Exporter was collecting metrics only from inside the container.

To monitor the real VPS host, Node Exporter was adjusted to use the host filesystem through the `--path.rootfs` parameter.

Configuration applied:

```yaml
command:
  - '--path.rootfs=/host'

volumes:
  - '/:/host:ro,rslave'
```

After this change, Grafana started showing real host metrics from the VPS instead of container-only metrics.

---

## Current Monitoring Scope

Currently monitored:

```text
Main VPS / HQ
```

Not yet monitored:

```text
Ubuntu-A
Ubuntu-B
```

Monitoring for the remote Ubuntu hosts will be implemented in future phases.

---

## Repository Structure

```text
bobhub/
│
├── README.md
│
├── docs/
│   ├── architecture.md
│   ├── monitoring.md
│   ├── network.md
│   └── roadmap.md
│
├── docker/
│   ├── nginx-proxy-manager/
│   ├── portainer/
│   ├── uptime-kuma/
│   ├── grafana/
│   ├── prometheus/
│   ├── node-exporter/
│   └── observability/
│
├── wireguard/
│
├── diagrams/
│
└── scripts/
```

---

## Technologies Used

* Linux
* Docker
* Docker Compose
* WireGuard
* pfSense
* Prometheus
* Grafana
* Node Exporter
* Portainer
* Nginx Proxy Manager
* Uptime Kuma
* Git
* GitHub

---

## Current Status

BobHub is currently in the initial observability phase.

Completed:

```text
Linux basics
Networking basics
WireGuard VPN
Git
GitHub
Docker
Docker Compose
Project documentation
Repository organization
Prometheus
Grafana
Node Exporter
Host monitoring
Observability v1
```

In progress / pending:

```text
Improve documentation
Create v1.0-observability release
Implement alerts
Monitor Ubuntu-A
Monitor Ubuntu-B
GitHub Actions
CI/CD
Ansible
Loki
Promtail
Centralized logging
OpenWebUI
ChatOps
```

---

## Roadmap

### Completed

* Linux
* Networking
* WireGuard
* Git
* GitHub
* Docker
* Docker Compose
* Documentation
* Diagrams
* Prometheus
* Grafana
* Node Exporter
* Observability

### Next Steps

1. Improve README
2. Create release `v1.0-observability`
3. Implement basic alerts
4. Monitor Ubuntu-A
5. Monitor Ubuntu-B
6. Implement GitHub Actions
7. Create CI/CD pipelines
8. Introduce Ansible
9. Implement Loki
10. Implement Promtail
11. Centralize logs
12. Deploy OpenWebUI
13. Explore ChatOps

---

## Technical Decisions

### Kubernetes is not part of the current phase

Kubernetes will not be used at this moment.

The current focus is to consolidate the following foundations before increasing the complexity of the environment:

* Docker
* Networking
* VPN
* Observability
* CI/CD
* Automation
* Infrastructure as Code

---

### Practical learning first

The project follows a hands-on learning approach.

The idea is to implement first, validate the behavior in practice, and then go deeper into theory when needed.

---

### Documentation-driven evolution

Every relevant change should generate:

* A Git commit
* Documentation updates
* Roadmap updates, when applicable

---

## Portfolio Purpose

BobHub also works as a technical portfolio.

It demonstrates the ability to design, deploy, document, and operate infrastructure components in a realistic environment.

The project shows practical experience with infrastructure operations, monitoring, VPN, containers, documentation, and the progressive adoption of DevOps practices.

---

## Author

Created and maintained by Vinicius Brobowski.

GitHub:

ViniciusBrobowski

Repository:

bobhub
