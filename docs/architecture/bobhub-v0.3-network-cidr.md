# BobHub v0.3.0 — Network and CIDR Design

## Status

```text
Defined
```

## Version

```text
BobHub v0.3.0
Multi-Cloud IaC, Security & Resilience
```

---

# Objective

This document defines the network addressing, subnet strategy, routing boundaries and hybrid connectivity model for BobHub v0.3.0.

The design covers:

- Existing BobHub home lab
- AWS primary cloud
- OCI active Disaster Recovery
- Azure shared data layer
- WireGuard overlay
- pfSense-to-AWS Site-to-Site VPN
- Future network expansion

No public cloud infrastructure should be provisioned without following this addressing baseline.

---

# Network Principles

BobHub v0.3.0 follows these principles:

- No overlapping CIDR ranges
- One major CIDR block per cloud
- Existing BobHub networks remain isolated
- Public IP addresses are used only where required
- Application workloads should be private where practical
- Cross-cloud routing is not enabled by default
- Hybrid routes must be explicitly defined
- Managed NAT services are not deployed automatically
- Network design must support future expansion
- Terraform will use this document as the addressing baseline

---

# Current Active BobHub Networks

The active local BobHub environment for v0.3.0 is:

| Environment | CIDR | Purpose |
|---|---|---|
| Home Lab / Site A | `10.10.40.0/24` | Local BobHub environment behind pfSense |
| WireGuard | `10.255.255.0/24` | BobHub overlay VPN |

The previous Site B environment is no longer part of the active v0.3.0 architecture.

Its historical documentation remains valid for previous BobHub versions.

---

# Multi-Cloud Address Plan

The following address spaces are reserved:

| Environment | CIDR | Role |
|---|---|---|
| Home Lab | `10.10.40.0/24` | Local infrastructure |
| AWS | `10.30.0.0/16` | Primary cloud |
| OCI | `10.40.0.0/16` | Active Disaster Recovery |
| Azure | `10.50.0.0/16` | Shared data layer / future private networking |
| WireGuard | `10.255.255.0/24` | Overlay VPN |

Architecture:

```text
BobHub
│
├── Home Lab
│   └── 10.10.40.0/24
│
├── AWS
│   └── 10.30.0.0/16
│
├── OCI
│   └── 10.40.0.0/16
│
├── Azure
│   └── 10.50.0.0/16
│
└── WireGuard
    └── 10.255.255.0/24
```

These networks do not overlap.

---

# AWS Network

## VPC

```text
10.30.0.0/16
```

AWS is the primary application cloud.

---

## AWS Subnets

Initial address allocation:

| Subnet | CIDR | Purpose |
|---|---|---|
| Public A | `10.30.10.0/24` | Public ingress / AZ A |
| Public B | `10.30.11.0/24` | Public ingress / AZ B |
| Application A | `10.30.20.0/24` | Application workloads / AZ A |
| Application B | `10.30.21.0/24` | Application workloads / AZ B |
| Reserved | `10.30.30.0/24+` | Future services |

Conceptually:

```text
AWS VPC
10.30.0.0/16
│
├── Public A
│   10.30.10.0/24
│
├── Public B
│   10.30.11.0/24
│
├── Application A
│   10.30.20.0/24
│
├── Application B
│   10.30.21.0/24
│
└── Reserved
    10.30.30.0/24+
```

---

# AWS Public Layer

The public network layer is intended for infrastructure that requires Internet-facing connectivity.

Expected ingress architecture:

```text
Internet
   ↓
AWS WAF
   ↓
Application Load Balancer
   ↓
Application Layer
```

The public subnets also provide the network structure required to distribute the regional ingress architecture across Availability Zones.

---

# AWS Application Layer

Application workloads should run without direct Internet exposure where practical.

Expected flow:

```text
ALB
 ↓
Traefik
 ↓
Application
```

Application networks:

```text
10.30.20.0/24
10.30.21.0/24
```

The first implementation may use limited compute resources for cost control while preserving the multi-AZ addressing design.

---

# OCI Network

## VCN

```text
10.40.0.0/16
```

OCI acts as the active Disaster Recovery environment.

---

## OCI Subnets

Initial allocation:

| Subnet | CIDR | Purpose |
|---|---|---|
| Public | `10.40.10.0/24` | Public ingress |
| Application | `10.40.20.0/24` | DR application workloads |
| Reserved | `10.40.30.0/24+` | Future services |

Architecture:

```text
OCI VCN
10.40.0.0/16
│
├── Public
│   10.40.10.0/24
│
├── Application
│   10.40.20.0/24
│
└── Reserved
    10.40.30.0/24+
```

OCI does not need to mirror the AWS subnet topology exactly.

The objective is functional equivalence at the application and Disaster Recovery layers.

---

# Azure Network

The following address space is reserved for Azure:

```text
10.50.0.0/16
```

However, BobHub v0.3.0 will not create a VNet only for architectural symmetry.

The initial Azure responsibility is:

```text
Azure PostgreSQL
```

Initial connectivity may use a controlled public endpoint with:

- TLS required
- Restricted firewall rules
- Strong authentication
- No unrestricted database exposure
- No credentials committed to Git

---

## Future Azure Private Networking

If private connectivity becomes part of the lab, the following ranges are reserved:

```text
Azure VNet
10.50.0.0/16

Integration
10.50.10.0/24

Database / Private Endpoint
10.50.20.0/24

Future
10.50.30.0/24+
```

These resources are reserved in the address plan but are not required to exist during the initial implementation.

---

# Hybrid Connectivity

BobHub will connect the existing home lab to AWS using AWS Site-to-Site VPN.

Architecture:

```text
Home Lab
10.10.40.0/24
      │
      ▼
   pfSense A
      │
      ▼
AWS Site-to-Site VPN Connection
      │
      ▼
AWS Virtual Private Gateway
      │
      ▼
AWS VPC
10.30.0.0/16
```

A Transit Gateway is not required for the initial BobHub architecture.

---

# AWS VPN Tunnel Model

One AWS Site-to-Site VPN connection provides redundant IPsec tunnels.

Conceptually:

```text
                         AWS VPC
                      10.30.0.0/16
                             │
                  Virtual Private Gateway
                             │
                  Site-to-Site VPN Connection
                             │
             ┌───────────────┴───────────────┐
             │                               │
        IPsec Tunnel 1                  IPsec Tunnel 2
             │                               │
             └───────────────┬───────────────┘
                             │
                          pfSense A
                             │
                      10.10.40.0/24
```

Both tunnels should be configured when practical so the lab also exercises VPN redundancy.

---

# VPN Routing

The VPN connection is bidirectional.

The same Site-to-Site VPN infrastructure carries traffic in both directions.

What differs is the routing information configured on each side.

pfSense must know:

```text
10.30.0.0/16
    ↓
AWS Site-to-Site VPN
```

AWS must know:

```text
10.10.40.0/24
    ↓
Virtual Private Gateway
    ↓
Site-to-Site VPN
```

Conceptually:

```text
10.10.40.0/24
      │
      │
      │     Same Site-to-Site VPN
      │
      ⇅
      │
      │
10.30.0.0/16
```

There are not separate Home-to-AWS and AWS-to-Home VPN connections.

---

# Initial Hybrid Routing Scope

Initial routed networks:

```text
Home Lab
10.10.40.0/24

AWS
10.30.0.0/16
```

Expected communication:

```text
10.10.40.0/24
        ⇅
     IPsec
        ⇅
10.30.0.0/16
```

Only required traffic will be allowed by firewall and security rules.

---

# WireGuard Isolation

The existing WireGuard overlay remains:

```text
10.255.255.0/24
```

It will not initially be routed through the AWS Site-to-Site VPN.

Architecture:

```text
WireGuard
10.255.255.0/24
      │
      └── Independent overlay


Home Lab
10.10.40.0/24
      │
   pfSense
      │
    IPsec
      │
      ▼
AWS
10.30.0.0/16
```

Combining WireGuard and IPsec routing may be evaluated later only if a real requirement exists.

---

# Cross-Cloud Routing

The initial architecture does not create private routing between:

```text
AWS ↔ OCI

AWS ↔ Azure

OCI ↔ Azure
```

Each cloud remains an independent network failure domain.

Cross-cloud private networking may be evaluated later.

---

# Public and Private Boundaries

Target model:

```text
Internet
   ↓
WAF
   ↓
Public Load Balancer
   ↓
Private Application Layer
   ↓
Shared Data Layer
```

Public exposure should exist only where required.

---

# NAT Strategy

Managed NAT gateways are not part of the default BobHub v0.3.0 baseline.

Before deploying a NAT Gateway, the implementation must document:

- Technical requirement
- Cloud-specific cost
- Expected lifetime
- Lower-cost alternatives
- Cleanup procedure

Possible outbound requirements include:

```text
Container image downloads
Package repositories
Operating system updates
External APIs
```

The selected solution will be decided during provider-specific implementation.

---

# Network Security

Network security should follow least-access principles.

AWS:

```text
Security Groups
Route Tables
Network ACLs where useful
```

OCI:

```text
Network Security Groups
Security Lists where appropriate
Route Tables
```

Azure:

```text
Database Firewall
Network Security Groups if VNet is introduced
```

Every significant network rule should have a documented purpose.

---

# DNS Connectivity

Global DNS will direct traffic to public regional ingress endpoints.

Conceptually:

```text
PowerDNS
   │
   ├── AWS public application endpoint
   │
   └── OCI public application endpoint
```

PowerDNS does not require private routing between the cloud environments.

Authoritative DNS must support:

```text
UDP/53
TCP/53
```

where applicable.

---

# Observability Connectivity

The existing BobHub VPS remains outside the AWS and OCI failure domains.

Initial monitoring can use public application health endpoints.

```text
BobHub VPS
    │
    ├── AWS /health
    ├── OCI /health
    ├── Global application endpoint
    └── DNS checks
```

Private monitoring connectivity can be introduced later if it provides meaningful learning value.

---

# CIDR Summary

```text
HOME LAB
10.10.40.0/24

AWS
10.30.0.0/16

AWS Public A
10.30.10.0/24

AWS Public B
10.30.11.0/24

AWS Application A
10.30.20.0/24

AWS Application B
10.30.21.0/24

OCI
10.40.0.0/16

OCI Public
10.40.10.0/24

OCI Application
10.40.20.0/24

AZURE RESERVED
10.50.0.0/16

WIREGUARD
10.255.255.0/24
```

---

# Final Network Architecture

```text
                               INTERNET
                                  │
                           Global DNS / GSLB
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼

             AWS 10.30.0.0/16           OCI 10.40.0.0/16
                    │                           │
               Public Layer                Public Layer
                    │                           │
              Application                  Application
                    │                           │
                    └────────────┬──────────────┘
                                 │
                                 ▼
                         Azure PostgreSQL

                     Azure CIDR reserved:
                         10.50.0.0/16


                       HOME LAB
                    10.10.40.0/24
                          │
                       pfSense A
                          │
            AWS Site-to-Site VPN Connection
                     /           \
               Tunnel 1         Tunnel 2
                     \           /
                          │
                          ▼
                    AWS 10.30.0.0/16


                       WireGuard
                    10.255.255.0/24
                   Independent Overlay
```

---

# Architecture Decision Summary

```text
Active Local Environment
Site A / pfSense A

Home CIDR
10.10.40.0/24

AWS CIDR
10.30.0.0/16

OCI CIDR
10.40.0.0/16

Azure Reserved CIDR
10.50.0.0/16

WireGuard CIDR
10.255.255.0/24

Hybrid Connectivity
pfSense A ↔ AWS

AWS VPN Endpoint
Virtual Private Gateway

Transit Gateway
Not required initially

AWS Site-to-Site VPN Connections
1

AWS IPsec Tunnels
2 redundant tunnels

WireGuard Through IPsec
No

Cross-Cloud Private Routing
No

Managed NAT Gateway by Default
No

Azure VNet Initially Required
No
```

---

# Conclusion

BobHub v0.3.0 now has a defined addressing and routing baseline.

The architecture separates:

```text
Home Lab
+
AWS
+
OCI
+
Azure
+
WireGuard
```

while preserving the ability to introduce additional private connectivity later.

The next BobHub infrastructure decisions can now be implemented without redefining the fundamental network architecture.