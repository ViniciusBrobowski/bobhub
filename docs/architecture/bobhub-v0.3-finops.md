# BobHub v0.3.0 — FinOps and Cost Strategy

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

This document defines the FinOps strategy and cost guardrails for BobHub v0.3.0.

The primary financial objective is:

```text
Target out-of-pocket cost
US$ 0
```

BobHub will use:

```text
Free Tier resources
+
Always Free resources
+
Promotional cloud credits
+
Ephemeral infrastructure
```

to build production-like multi-cloud laboratories while avoiding unnecessary personal spending.

The objective is not to avoid paid cloud services completely.

Managed services that provide meaningful technical learning may be used when their cost can be covered by available credits and their lifecycle is controlled.

---

# FinOps Architecture Principle

BobHub follows an:

```text
Ephemeral-by-default
```

infrastructure model.

The normal cloud study lifecycle is:

```text
Start study session
        ↓
terraform apply
        ↓
Provision infrastructure
        ↓
Study
Test
Break
Observe
        ↓
terraform destroy
        ↓
Validate provider inventory
        ↓
End session
```

The main cost target is:

```text
Zero unnecessary idle cost
```

---

# Funding Strategy

BobHub v0.3.0 follows this priority:

```text
1. Free Tier / Always Free

2. Promotional cloud credits

3. Temporary paid resources funded by credits

4. Personal out-of-pocket spending
   Avoid
```

Cloud credits are treated as finite project budget.

They do not remove the requirement for:

```text
Cost monitoring
Billing alerts
Cleanup
Tagging
Architecture review
Terraform destroy
```

---

# AWS Strategy

A new AWS account eligible for the available Free Tier and promotional credit program is preferred for BobHub v0.3.0.

AWS will be the primary environment for learning services such as:

```text
VPC

EC2

Application Load Balancer

AWS WAF

Site-to-Site VPN

CloudWatch

Security Groups

Public IPv4 where required
```

Paid AWS resources may be used when they are part of the learning objective.

However, recurring paid resources should normally be destroyed when the study session ends.

---

# AWS Resource Lifecycle

Expected model:

```text
AWS VPC
Temporary / Experiment

EC2
Temporary / Experiment

Application Load Balancer
Temporary / Experiment

AWS WAF
Temporary / Experiment

Site-to-Site VPN
Temporary / Experiment

Public IPv4
Temporary where possible

CloudWatch
Controlled retention
```

The project should avoid leaving paid AWS resources running only because they may be useful later.

Infrastructure can be recreated from Terraform.

---

# Load Balancer Strategy

Managed Load Balancers are intentional learning components.

The project will use real cloud Load Balancer services rather than replacing them only to avoid usage cost.

The AWS Load Balancer lab should cover:

```text
Application Load Balancer

Listeners

Target Groups

Health Checks

Backend registration

Traffic distribution

Multi-AZ behavior

Backend failure

HTTP / HTTPS

TLS

Terraform provisioning
```

Expected architecture:

```text
Internet
   ↓
AWS WAF
   ↓
Application Load Balancer
   ↓
Traefik
   ↓
Application
```

After isolated Load Balancer experiments:

```text
terraform destroy
```

should remove the temporary infrastructure when it is no longer required.

---

# WAF Strategy

AWS WAF is also an intentional learning component.

The project should use the real service to understand:

```text
Web ACLs

Managed Rules

Custom Rules

Rule priority

Allow behavior

Block behavior

SQL injection detection

Cross-site scripting detection

Rate limiting

Request inspection

Logging

Terraform provisioning
```

WAF should not remain provisioned indefinitely only because it has already been configured.

Infrastructure as Code must make recreation predictable.

---

# Hybrid VPN Strategy

BobHub will implement AWS Site-to-Site VPN between:

```text
Home Lab
10.10.40.0/24
      │
      ▼
   pfSense A
      │
      │
     IPsec
      │
      ▼
AWS VPC
10.30.0.0/16
```

The VPN is part of the learning scope.

It does not need to remain active permanently.

Expected lifecycle:

```text
Hybrid networking study
        ↓
Create VPN
        ↓
Configure pfSense
        ↓
Validate routes
        ↓
Test connectivity
        ↓
Document results
        ↓
Destroy AWS VPN resources
```

This prevents idle VPN charges when the lab is not being used.

---

# NAT Strategy

Managed NAT Gateways are not included in the default BobHub architecture.

Before creating one, the project must answer:

```text
Why is Internet egress required?

Which workload requires it?

What is the recurring cost?

What traffic charges exist?

Is there a lower-cost alternative?

How long will it exist?

How will it be destroyed?
```

A NAT Gateway should only be introduced when the technical learning value justifies it.

---

# Public IPv4 Strategy

Public IPv4 addresses should only exist where technically necessary.

Preferred architecture:

```text
Internet
   ↓
Public Entry Point
   ↓
Private Application Layer
```

Instead of:

```text
Internet
   ↓
Public IP on every workload
```

Unused public IP resources must be removed after experiments.

---

# OCI Strategy

OCI will provide the active Disaster Recovery environment.

Always Free resources should be preferred where they satisfy the technical requirement.

Target OCI model:

```text
OCI VCN
        │
        ├── Free / Always Free resources where eligible
        │
        └── Temporary paid resources when required
```

Resources that remain within eligible free allocations may stay operational.

This makes OCI suitable for maintaining a minimal DR baseline.

Paid OCI services should follow the same:

```text
Ephemeral-by-default
```

strategy used in AWS.

---

# Azure Strategy

Azure provides the shared PostgreSQL data layer.

The database is a laboratory resource and does not contain production data.

Therefore persistence between study sessions is not mandatory.

Possible lifecycle:

```text
Start study session
        ↓
Create Azure PostgreSQL
        ↓
Configure database
        ↓
Run AWS / OCI application tests
        ↓
Complete lab
        ↓
Destroy Azure PostgreSQL
```

The smallest practical database configuration should be used.

Production-scale features should not be enabled unless they are specifically being studied.

Examples:

```text
High Availability

Read Replicas

Large storage allocations

Long backup retention

Large compute tiers
```

---

# Terraform Backend

The remote Terraform backend defined by the BobHub state architecture is considered control infrastructure.

Target model:

```text
HCP Terraform
```

The Terraform control state must remain independent from:

```text
AWS
OCI
Azure
```

Destroying a cloud stack must not destroy the state required to recreate that environment.

---

# Existing BobHub Infrastructure

Existing infrastructure that does not create additional v0.3 cloud cost may remain active.

Examples:

```text
BobHub VPS

Prometheus

Grafana

Alertmanager

Uptime Kuma

WireGuard

Existing central observability
```

These resources are outside the cloud failure domains being tested.

---

# Cost Classes

Every cloud resource should conceptually belong to one of three cost classes.

## Persistent

Resources that may remain deployed because they provide continuous value with no relevant incremental cost or are explicitly justified.

Example:

```text
HCP Terraform free tier

Existing BobHub VPS services

OCI Always Free resources where eligible
```

## Temporary

Resources required during part of the v0.3 implementation but not intended to remain indefinitely.

Example:

```text
Temporary database

Temporary compute

Temporary network services
```

## Experiment

Resources created specifically for a laboratory or failure test.

Example:

```text
AWS WAF lab

ALB lab

Site-to-Site VPN lab

DR capacity test

Additional compute instance

Security test infrastructure
```

Experiment resources should normally be destroyed when the session finishes.

---

# Resource Tagging

Resources should use consistent metadata where supported.

Baseline:

```text
Project     = BobHub
Version     = v0.3.0
Environment = lab
ManagedBy   = Terraform
Purpose     = <resource-purpose>
CostClass   = <persistent|temporary|experiment>
```

Example:

```hcl
tags = {
  Project     = "BobHub"
  Version     = "v0.3.0"
  Environment = "lab"
  ManagedBy   = "Terraform"
  Purpose     = "aws-alb-lab"
  CostClass   = "experiment"
}
```

Tags should make BobHub resources easy to identify in:

```text
Cloud inventory

Billing reports

Cost Explorer

Cleanup reviews
```

---

# Budget Strategy

Cloud budgets and billing alerts must be configured before significant paid infrastructure is provisioned.

The financial objective is:

```text
Out-of-pocket
US$ 0
```

Therefore alerts should focus on:

```text
Unexpected consumption

Rapid credit usage

Resources left running

Unexpected paid services
```

Exact monetary alert thresholds should be defined when each provider account is configured.

They should consider:

```text
Available promotional credits

Free Tier eligibility

Expected lab duration

Current provider pricing
```

---

# Pricing Documentation

Exact cloud prices should not be hard-coded permanently into architecture documentation.

Cloud pricing changes.

Instead, provider-specific implementation issues should validate:

```text
Current service price

Charging model

Expected lab duration

Expected experiment cost

Free Tier coverage

Credit eligibility
```

Example:

```text
Service
AWS Application Load Balancer

Purpose
Load balancing and HA lab

Pricing
Validate official AWS pricing during implementation

CostClass
Experiment

Expected lifecycle
Study session

Cleanup
terraform destroy
```

---

# Pre-Apply Cost Checklist

Before provisioning a significant managed resource:

```text
What will Terraform create?

Why do we need it?

What will we learn?

Is it Free Tier eligible?

Can promotional credits cover it?

Does it charge while idle?

Does it charge by hour?

Does it charge by request?

Does it charge by traffic?

Does it require another paid resource?

Does it need a public IPv4?

Does it need to survive the study session?

How will it be destroyed?
```

If these questions cannot be answered, the resource should not yet be provisioned.

---

# End-of-Session Checklist

At the end of every cloud study session:

```text
Review Terraform state
        ↓
Destroy experiment resources
        ↓
Destroy temporary billable resources
        ↓
Check cloud console
        ↓
Check compute
        ↓
Check disks / volumes
        ↓
Check public IP addresses
        ↓
Check Load Balancers
        ↓
Check WAF resources
        ↓
Check VPN resources
        ↓
Check databases
        ↓
Confirm only expected persistent resources remain
```

Terraform state alone should not be considered sufficient evidence that no billable resources remain.

The cloud provider inventory must also be reviewed.

---

# Future Automation

BobHub may later introduce helpers such as:

```text
scripts/lab/start-v03.ps1

scripts/lab/stop-v03.ps1
```

Possible responsibilities:

```text
Start environment

Validate Terraform configuration

Provision selected stacks

Destroy selected stacks

Check for remaining paid resources

Display cleanup checklist
```

This automation is not required for the initial FinOps architecture definition.

---

# Disaster Recovery Cost Strategy

The BobHub Disaster Recovery test will intentionally use additional infrastructure.

Scenario:

```text
AWS
70%

OCI
30%

      ↓

Destroy AWS

      ↓

OCI
100%

      ↓

Rebuild AWS

      ↓

Failback

10/90

30/70

50/50

70/30
```

Temporary cost generated during this experiment is acceptable when:

```text
It is intentional

It is understood

It is covered by available credits

It contributes directly to the DR learning objective
```

After the experiment, temporary capacity must be reviewed and removed.

---

# High-Attention AWS Resources

Resources requiring specific cost review:

```text
Application Load Balancer

AWS WAF

Site-to-Site VPN

Public IPv4

EC2

EBS

CloudWatch

NAT Gateway if ever introduced
```

---

# High-Attention OCI Resources

Resources requiring cost review:

```text
Compute

Load Balancer

WAF

Block Volumes

Object Storage

Logging

Public IP resources
```

Always Free eligibility should be verified during implementation.

---

# High-Attention Azure Resources

Resources requiring cost review:

```text
PostgreSQL

Compute sizing

Storage

Backup retention

Networking

Private endpoints if introduced

Monitoring

Logging
```

---

# FinOps Decision Summary

```text
Target Out-of-Pocket Cost
US$ 0

Primary Funding
Free Tier + promotional cloud credits

Infrastructure Model
Ephemeral by default

Paid Persistent Infrastructure
Avoid

Real Managed Services
Allowed when part of learning

AWS ALB
Real service / experiment

AWS WAF
Real service / experiment

AWS Site-to-Site VPN
Real service / experiment

NAT Gateway
Not part of default architecture

Azure PostgreSQL
Minimum practical sizing / ephemeral where practical

OCI Always Free
Preferred for persistent DR baseline

HCP Terraform
Persistent control infrastructure

Budgets
Required

Billing Alerts
Required

Resource Tags
Required where supported

Terraform Destroy
Normal operational procedure

Cloud Inventory Review
Required after cleanup
```

---

# Success Criteria

The FinOps strategy is successful when BobHub can:

```text
Provision real cloud services

Learn production-relevant architecture

Perform security experiments

Perform Disaster Recovery experiments

Use Load Balancers

Use WAF

Use hybrid VPN

Destroy temporary infrastructure

Avoid unnecessary idle cloud cost

Remain at or near US$ 0 out-of-pocket cost
```

---

# Out of Scope

This document does not yet:

```text
Create AWS budgets

Create AWS billing alerts

Create OCI budgets

Create Azure budgets

Create cloud accounts

Provision infrastructure

Configure ALB

Configure WAF

Configure VPN

Configure PostgreSQL

Create cleanup automation
```

These tasks belong to later BobHub v0.3.0 implementation issues.

---

# Conclusion

BobHub v0.3.0 does not sacrifice technical learning solely to achieve zero cloud usage.

Instead, it combines:

```text
Real Cloud Services
+
Free Tier
+
Promotional Credits
+
Terraform
+
Ephemeral Infrastructure
+
FinOps Guardrails
```

The goal is to gain practical experience with production-relevant cloud services while maintaining:

```text
Target out-of-pocket cost
US$ 0
```

and:

```text
Target unnecessary idle cost
US$ 0
```

This FinOps strategy becomes a mandatory architecture constraint for all subsequent BobHub v0.3.0 cloud implementation.