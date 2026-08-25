# BobHub v0.3.0 — Terraform State Architecture

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

This document defines the Terraform state architecture, lifecycle boundaries and dependency strategy for BobHub v0.3.0.

BobHub v0.3.0 introduces infrastructure across:

- AWS
- Oracle Cloud Infrastructure
- Microsoft Azure
- Global infrastructure services

The Terraform architecture must allow each infrastructure domain to be managed independently.

The design must also support the planned Disaster Recovery exercises where AWS infrastructure can be intentionally destroyed and rebuilt without affecting OCI, Azure, global infrastructure or observability.

---

# State Architecture Principles

BobHub v0.3.0 follows these Terraform state principles:

- One infrastructure lifecycle per Terraform state
- No single multi-cloud Terraform state
- Remote state instead of workstation-only state
- Terraform state must remain outside Git
- State must remain available during cloud failure tests
- AWS destruction must not affect OCI or Azure state
- OCI destruction must not affect AWS or Azure state
- Cross-state dependencies must be minimized
- Sensitive values in state must be treated as secrets
- Each Terraform root module must support an independent lifecycle
- Disaster Recovery operations must not depend on the cloud being destroyed

---

# Previous State Model

BobHub v0.2.0 used local Terraform state for the Proxmox lab.

Conceptually:

```text
terraform/
└── proxmox/
    └── terraform.tfstate
```

This model was sufficient for the initial Infrastructure as Code implementation.

BobHub v0.3.0 introduces multiple infrastructure failure domains and therefore requires a more structured state strategy.

---

# Multi-Cloud Terraform Structure

The proposed repository structure is:

```text
terraform/
├── proxmox/
│   └── BobHub v0.2 implementation
│
└── multicloud/
    ├── aws-primary/
    ├── oci-dr/
    ├── azure-data/
    └── global/
```

Each directory represents an independent Terraform root module.

---

# Infrastructure Lifecycle Boundaries

Each root module owns only its corresponding infrastructure responsibility.

```text
aws-primary
    ↓
AWS infrastructure

oci-dr
    ↓
OCI infrastructure

azure-data
    ↓
Azure infrastructure

global
    ↓
Global and shared infrastructure
```

No Terraform root module should manage resources that belong to another lifecycle unless there is a strong architectural reason.

---

# AWS State

Terraform root:

```text
terraform/multicloud/aws-primary/
```

Expected responsibilities:

- AWS VPC
- Subnets
- Route tables
- Internet Gateway
- Security Groups
- Compute
- Application Load Balancer
- AWS WAF
- Traefik infrastructure
- Application infrastructure
- AWS Site-to-Site VPN
- AWS-specific monitoring integrations

State:

```text
bobhub-v03-aws-primary
```

The AWS stack must support:

```text
terraform plan

terraform apply

terraform destroy

terraform apply
```

without modifying infrastructure managed by other states.

---

# OCI State

Terraform root:

```text
terraform/multicloud/oci-dr/
```

Expected responsibilities:

- OCI VCN
- Subnets
- Route tables
- Network Security Groups
- OCI Compute
- OCI Load Balancer
- OCI WAF
- Traefik infrastructure
- DR application infrastructure
- OCI Object Storage where applicable
- OCI-specific monitoring integrations

State:

```text
bobhub-v03-oci-dr
```

OCI must remain operational while AWS is destroyed.

---

# Azure State

Terraform root:

```text
terraform/multicloud/azure-data/
```

Expected responsibilities:

- Azure Resource Group
- Azure PostgreSQL
- Database networking where required
- Database firewall rules
- Future Azure VNet resources if introduced
- Azure-specific monitoring integrations

State:

```text
bobhub-v03-azure-data
```

The Azure lifecycle must remain independent from AWS and OCI.

---

# Global State

Terraform root:

```text
terraform/multicloud/global/
```

Expected responsibilities may include:

- Global DNS configuration
- PowerDNS-related automation
- Shared global infrastructure values
- Global traffic configuration
- Infrastructure that should not belong to a regional cloud lifecycle

State:

```text
bobhub-v03-global
```

The global infrastructure lifecycle must remain independent from:

```text
AWS
OCI
Azure
```

---

# State Isolation

The architecture must never use a single state such as:

```text
terraform.tfstate

AWS
+
OCI
+
Azure
+
Global
```

This would create unnecessary lifecycle coupling.

Instead:

```text
                 Terraform Remote Backend
                         │
          ┌──────────────┼──────────────┬──────────────┐
          │              │              │              │
          ▼              ▼              ▼              ▼

     AWS State       OCI State      Azure State    Global State

     aws-primary      oci-dr         azure-data       global
```

Each state is independent.

---

# Remote State

BobHub v0.3.0 will evolve from local Terraform state to remote Terraform state.

The preferred architecture is a dedicated Terraform remote backend that remains outside the lifecycle of the infrastructure environments being tested.

Conceptually:

```text
                     Remote Backend
                          │
               Terraform State Platform
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
       AWS               OCI              Azure
```

The backend should not disappear when one of the cloud environments is destroyed.

---

# Preferred Remote Backend

The initial preferred remote state platform is:

```text
HCP Terraform
```

The purpose of using HCP Terraform is to provide:

- Remote state storage
- State isolation
- State history
- Centralized state access
- Terraform workspace separation
- Reduced dependency on the local workstation

The exact backend configuration will be implemented in a later issue.

---

# Terraform Workspaces

The planned HCP Terraform workspace structure is:

```text
bobhub-v03-aws-primary

bobhub-v03-oci-dr

bobhub-v03-azure-data

bobhub-v03-global
```

Each workspace represents a different infrastructure lifecycle.

This is intentionally different from:

```text
one workspace
    ├── AWS
    ├── OCI
    └── Azure
```

which would recreate the same lifecycle coupling that the architecture is designed to avoid.

---

# Why the Backend Must Be Independent

BobHub v0.3.0 includes an intentional AWS failure scenario.

The planned experiment includes:

```text
AWS running
    ↓
terraform destroy
    ↓
AWS infrastructure removed
    ↓
OCI continues serving traffic
    ↓
AWS rebuilt
```

If Terraform state were stored only inside AWS, the control plane used to rebuild AWS could become unnecessarily dependent on the environment being destroyed.

The state architecture therefore separates:

```text
Infrastructure Failure Domain

from

Terraform Control State
```

---

# Disaster Recovery Requirement

The following operation:

```bash
cd terraform/multicloud/aws-primary
terraform destroy
```

must affect only infrastructure represented by:

```text
bobhub-v03-aws-primary
```

Expected result:

```text
AWS Application Infrastructure
DESTROYED

OCI
RUNNING

Azure
RUNNING

Global DNS
RUNNING

BobHub VPS
RUNNING

Central Observability
RUNNING

Terraform Remote Backend
RUNNING
```

This behavior is a core BobHub v0.3.0 architectural requirement.

---

# Recovery Requirement

After the AWS failure experiment:

```bash
terraform apply
```

inside:

```text
terraform/multicloud/aws-primary/
```

must rebuild AWS infrastructure using the existing AWS state lifecycle.

Conceptually:

```text
AWS Destroyed
      ↓
Terraform configuration remains
      ↓
Remote state remains available
      ↓
terraform apply
      ↓
AWS recreated
```

The operation must not require rebuilding OCI, Azure or global infrastructure.

---

# Cross-State Dependencies

Some infrastructure values will naturally need to be consumed by other stacks.

Examples include:

```text
Azure PostgreSQL hostname

AWS regional public endpoint

OCI regional public endpoint

Global DNS targets

Monitoring endpoints
```

However, these requirements must not result in a single Terraform state.

---

# Cross-State Dependency Principle

Dependencies should flow through explicit outputs and configuration rather than direct resource ownership across states.

Conceptually:

```text
azure-data
    │
    └── output
        postgres_hostname
              │
              ▼
       Configuration Layer
          /          \
         ▼            ▼
  aws-primary       oci-dr
```

The AWS Terraform state does not own Azure PostgreSQL.

The OCI Terraform state does not own Azure PostgreSQL.

They only consume information required to connect to it.

---

# Cross-State Coupling

The architecture should avoid creating dependency chains such as:

```text
AWS state
   ↓
OCI state
   ↓
Azure state
   ↓
Global state
```

because this creates hidden coupling between environments.

Preferred model:

```text
             Shared Configuration
                    │
       ┌────────────┼────────────┐
       │            │            │
       ▼            ▼            ▼
      AWS          OCI         Azure
```

Each stack should understand only the external values it actually requires.

---

# Terraform Remote State Data

Terraform supports consuming outputs from another state.

However, BobHub will use direct remote-state dependencies carefully.

Reasons include:

- Increased coupling
- State access requirements
- Sensitive output exposure
- Operational dependency between stacks

Where practical, external values may instead be supplied through:

- Terraform variables
- Environment variables
- CI/CD variables
- Secret management platforms
- Explicit configuration files excluded from Git
- DNS

The final mechanism will depend on the specific integration.

---

# Terraform State Security

Terraform state must be considered sensitive.

State can contain:

- Resource identifiers
- Internal IP addresses
- Hostnames
- Configuration values
- Generated credentials
- Provider-returned sensitive attributes
- Database information

Even when a Terraform variable is marked:

```hcl
sensitive = true
```

its value may still exist inside Terraform state.

The `sensitive` attribute primarily prevents accidental display in normal Terraform output.

It does not mean that the value is removed from state.

---

# Git Security

Terraform state must never intentionally be committed to the BobHub repository.

Files that must remain excluded include:

```text
*.tfstate

*.tfstate.*

terraform.tfvars

.terraform/

override.tf

override.tf.json
```

Environment-specific sensitive files must also remain outside version control.

---

# Cloud Credentials

Cloud credentials must not be stored directly inside Terraform source files.

Examples that must not be committed:

```text
AWS access keys

OCI private keys

OCI API fingerprints where sensitive context exists

Azure client secrets

Database passwords

PowerDNS credentials

Terraform tokens

SSH private keys
```

Authentication strategy will be defined during each provider implementation.

---

# Outputs

Terraform outputs should expose only information that is operationally required.

Good examples:

```text
aws_alb_dns_name

oci_lb_public_ip

postgres_hostname
```

Outputs should not unnecessarily expose:

```text
passwords

private keys

tokens

cloud secrets
```

---

# Terraform Directory Isolation

Each stack must be executable independently.

Example:

```powershell
cd terraform\multicloud\aws-primary
terraform init
terraform plan
```

The same principle applies to:

```text
oci-dr

azure-data

global
```

Running Terraform from one root must not automatically initialize or modify another root.

---

# Provider Isolation

Each Terraform root module should primarily configure only the provider or providers required for its responsibility.

Conceptually:

```text
aws-primary
    └── AWS provider

oci-dr
    └── OCI provider

azure-data
    └── AzureRM provider

global
    └── providers required for global services
```

This reduces provider complexity and makes each infrastructure layer easier to understand.

---

# Terraform Lock Files

Each Terraform root module may maintain its own:

```text
.terraform.lock.hcl
```

The lock file should be committed to Git.

This ensures provider version selection remains reproducible.

Conceptually:

```text
aws-primary/
└── .terraform.lock.hcl

oci-dr/
└── .terraform.lock.hcl

azure-data/
└── .terraform.lock.hcl
```

---

# Local State Usage

Local state may still appear temporarily during:

- Experiments
- Backend initialization
- Backend migration
- Isolated Terraform learning exercises

However, local state is not the target architecture for BobHub v0.3.0.

The final cloud infrastructure states should use the defined remote backend.

---

# State Migration

If a stack starts with local state during development and later moves to the remote backend, Terraform state migration must be performed intentionally.

Conceptually:

```text
Local State
    ↓
Backend Configuration
    ↓
terraform init
    ↓
State Migration
    ↓
Remote State
```

The migration process must be documented if used.

---

# State Locking

Concurrent Terraform operations against the same infrastructure state must be prevented where supported by the selected backend.

Example problem:

```text
Operator A
terraform apply

Operator B
terraform apply

Same state
```

State locking protects against conflicting infrastructure updates.

Remote backend behavior will be validated during implementation.

---

# State History

Remote state history is valuable because infrastructure state can change during:

- Apply
- Destroy
- DR tests
- Recovery
- Failback
- Configuration changes

State history provides additional operational evidence for BobHub experiments.

---

# Environment Lifecycle Model

The final lifecycle model is:

```text
AWS
Apply
Destroy
Rebuild
Independent


OCI
Apply
Destroy
Rebuild
Independent


Azure
Apply
Destroy
Rebuild
Independent


Global
Apply
Update
Independent
```

---

# Failure Domains

Terraform state architecture mirrors the BobHub infrastructure failure domains.

```text
Failure Domain 1
AWS

Failure Domain 2
OCI

Failure Domain 3
Azure

Failure Domain 4
Global Infrastructure

Control State
Remote Terraform Backend
```

The control state is intentionally separated from the infrastructure failure domains being tested.

---

# Repository Structure

Target structure:

```text
terraform/
├── proxmox/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── providers.tf
│
└── multicloud/
    │
    ├── aws-primary/
    │   ├── providers.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── main.tf
    │
    ├── oci-dr/
    │   ├── providers.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── main.tf
    │
    ├── azure-data/
    │   ├── providers.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── main.tf
    │
    └── global/
        ├── providers.tf
        ├── variables.tf
        ├── outputs.tf
        └── main.tf
```

The exact files will be created during provider-specific implementation issues.

---

# Architecture Decisions

```text
Terraform State Model
Remote

Remote Backend
HCP Terraform

State Count
4 independent states

AWS Workspace
bobhub-v03-aws-primary

OCI Workspace
bobhub-v03-oci-dr

Azure Workspace
bobhub-v03-azure-data

Global Workspace
bobhub-v03-global

Single Multi-Cloud State
No

Terraform State in Git
Never

State Sensitive
Yes

Cross-State Dependencies
Minimized

AWS Destroy Affects OCI
No

AWS Destroy Affects Azure
No

AWS Destroy Affects Global
No

Backend Depends on AWS
No

Backend Depends on OCI
No

Backend Depends on Azure
No

Provider Lock Files in Git
Yes
```

---

# Validation Scenario

The state architecture will eventually be validated with the following scenario:

```text
All environments running
        ↓
Select aws-primary
        ↓
terraform destroy
        ↓
AWS removed
        ↓
OCI remains operational
Azure remains operational
Global infrastructure remains operational
Terraform backend remains operational
        ↓
terraform apply
        ↓
AWS rebuilt
```

Successful completion of this scenario will provide evidence that the state boundaries are functioning as designed.

---

# Out of Scope

This architecture does not yet implement:

- Terraform backend configuration
- HCP Terraform workspace creation
- AWS provider authentication
- OCI provider authentication
- Azure provider authentication
- Terraform modules
- Cloud infrastructure
- CI/CD Terraform execution

These belong to later BobHub v0.3.0 implementation issues.

---

# Conclusion

BobHub v0.3.0 uses Terraform state boundaries that match infrastructure lifecycle and failure boundaries.

The architecture evolves from:

```text
BobHub v0.2
Local Terraform
Single Proxmox environment
```

to:

```text
BobHub v0.3
Remote Terraform State
+
Independent Cloud Lifecycles
+
Disaster Recovery
```

The final model is:

```text
                    HCP Terraform
                         │
           ┌─────────────┼─────────────┐
           │             │             │
           ▼             ▼             ▼
          AWS           OCI          Azure
           │             │             │
           └─────────────┼─────────────┘
                         │
                       Global
```

Infrastructure can therefore be provisioned, destroyed and rebuilt independently without turning the entire multi-cloud environment into one Terraform lifecycle.