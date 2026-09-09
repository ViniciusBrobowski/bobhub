# BobHub v0.3.0 — Azure PostgreSQL and OCI Integration Checkpoint

## Overview

This checkpoint documents the implementation and validation of the shared Azure PostgreSQL data layer for BobHub v0.3.0 and its integration with the existing OCI application environment.

The delivery was tracked through GitHub Issue:

```text
#59 — Provision Azure PostgreSQL shared data layer and integrate OCI application
```

The objective was to establish the first real cross-cloud application dependency in BobHub:

```text
OCI Application
      ↓
Azure PostgreSQL
```

This implementation creates the shared data foundation that will later be reused by the AWS primary application environment.

Future target:

```text
             Azure PostgreSQL
              ↑           ↑
              |           |
            OCI          AWS
         Active DR      Primary
```

---

# Architecture

The final validated application path is:

```text
Internet
   ↓
OCI WAF
   ↓
OCI Load Balancer
   ↓
Private OCI Compute
   ↓
Traefik
   ↓
BobHub Application
   ↓
TLS PostgreSQL Connection
   ↓
OCI NAT Gateway
   ↓
Internet
   ↓
Azure Database for PostgreSQL
```

The OCI application instance remains private and has no public IP.

Administrative access continues to use OCI Bastion.

Outbound database traffic uses the OCI NAT Gateway.

---

# Azure Data Layer

The Azure data layer is isolated in:

```text
terraform/multicloud/azure-data/
```

The Terraform root manages only Azure data-layer resources.

The infrastructure includes:

```text
Azure Resource Group
        ↓
Azure PostgreSQL Flexible Server
        ↓
BobHub Database
        ↓
OCI-restricted Firewall Rule
```

The Terraform state is isolated through the HCP Terraform workspace:

```text
bobhub-v03-azure-data
```

Execution mode:

```text
Local
```

HCP Terraform is used only for remote state storage while Terraform execution remains local.

---

# Azure PostgreSQL

The database platform uses:

```text
Azure Database for PostgreSQL Flexible Server
```

Main configuration:

```text
PostgreSQL version: 16
Region: Brazil South
Compute tier: Burstable
SKU: B_Standard_B1ms
Storage: 32 GiB
Backup retention: 7 days
High Availability: disabled
Geo-redundant backup: disabled
Public network access: enabled
Password authentication: enabled
Microsoft Entra authentication: disabled
```

Logical database:

```text
bobhub
```

The configuration prioritizes:

```text
Low lab cost
Terraform reproducibility
Controlled network access
TLS
Cross-cloud compatibility
Simple lifecycle management
```

---

# Network Access Strategy

Private cross-cloud networking is not implemented in this phase.

The initial connectivity model intentionally uses the Azure PostgreSQL public endpoint with restricted firewall access.

Traffic path:

```text
OCI Private Compute
      ↓
OCI NAT Gateway
      ↓
OCI NAT Public IP
      ↓
Azure PostgreSQL Firewall
      ↓
Azure PostgreSQL
```

The Azure firewall rule allows only the current OCI NAT public egress IP.

The implementation does not use:

```text
0.0.0.0/0
```

The OCI NAT public IP is exported through the OCI Terraform root and passed into the Azure Terraform root.

OCI output:

```text
nat_gateway_public_ip
```

Azure input:

```text
oci_nat_public_ip
```

The firewall rule uses the same start and end IP address, providing the equivalent of a single-host `/32` rule.

---

# Terraform State Separation

The OCI and Azure environments remain independent.

```text
terraform/multicloud/oci-dr
→ OCI lifecycle

terraform/multicloud/azure-data
→ Azure data-layer lifecycle
```

The Azure Terraform root does not manage OCI resources.

The OCI Terraform root does not manage Azure resources.

The only integration between both roots is the OCI NAT public IP being passed as an input to Azure.

This preserves independent infrastructure lifecycle management.

---

# PostgreSQL Client Automation

The PostgreSQL client was installed on the OCI application instance through Ansible.

The existing playbook:

```text
ansible/playbooks/oci-application.yml
```

was extended to install:

```text
postgresql-client
```

This avoids manual long-lived package configuration on the server.

---

# Connectivity Validation

Connectivity was validated directly from the private OCI application instance.

## DNS

Azure PostgreSQL hostname:

```text
psql-bobhub-v03-shared-data.postgres.database.azure.com
```

DNS resolution succeeded from OCI.

Example:

```text
Azure PostgreSQL hostname
→ public Azure PostgreSQL address
```

Result:

```text
DNS resolution: successful
```

---

## TCP

Port connectivity was validated from OCI:

```text
TCP 5432
```

Result:

```text
Connection succeeded
```

This validated the path:

```text
OCI Compute
   ↓
OCI NAT
   ↓
Azure Firewall
   ↓
PostgreSQL :5432
```

---

# TLS Validation

The first PostgreSQL connectivity test used:

```text
sslmode=require
```

This confirmed encrypted TLS connectivity.

The final validation used:

```text
sslmode=verify-full
```

with the operating system CA bundle:

```text
/etc/ssl/certs/ca-certificates.crt
```

The successful connection confirmed:

```text
TLS encryption
Certificate chain validation
Hostname validation
```

Validated protocol:

```text
TLSv1.3
```

Validated cipher:

```text
TLS_AES_256_GCM_SHA384
```

The application also uses:

```text
sslmode=verify-full
```

for runtime database connectivity.

---

# Database Validation

The PostgreSQL connection from OCI successfully validated:

```text
Authentication
SELECT
INSERT
Readback
```

PostgreSQL version query:

```sql
SELECT version();
```

Result confirmed:

```text
PostgreSQL 16
```

A validation table was created:

```text
connectivity_test
```

Conceptual structure:

```text
id
source_cloud
message
created_at
```

Validation data was inserted from OCI and successfully read back.

Example:

```text
source_cloud=oci
message=OCI application successfully reached Azure PostgreSQL
```

This proved real cross-cloud read/write access.

---

# Application Database User

A dedicated runtime PostgreSQL role was created:

```text
bobhub_app
```

The application does not use the PostgreSQL administrator account.

The runtime role has permissions required to operate application data while not having schema creation privileges.

Validated permissions include:

```text
CONNECT
USAGE on public schema
SELECT
INSERT
UPDATE
DELETE
Sequence usage
```

Schema creation validation:

```text
CREATE privilege on public schema
→ false
```

This establishes a least-privilege runtime database identity.

---

# Application Runtime

The previous BobHub demonstration application used a static Nginx container.

To support real database validation, it was replaced by a lightweight Python backend.

Application files:

```text
ansible/files/bobhub-app/
├── app.py
├── Dockerfile
└── requirements.txt
```

Runtime stack:

```text
Python
Flask
Gunicorn
psycopg
```

Container image:

```text
bobhub-app:v0.3.0
```

Application port:

```text
8000
```

Traefik continues to expose the application through port 80.

Architecture:

```text
Traefik :80
    ↓
BobHub App :8000
    ↓
Azure PostgreSQL
```

---

# Runtime Secrets

Database credentials are not embedded in:

```text
Terraform source
Ansible playbooks
Dockerfile
Application source
Git repository
Documentation
```

The Ansible runtime receives database configuration through environment variables:

```text
BOBHUB_DB_HOST
BOBHUB_DB_NAME
BOBHUB_DB_USER
BOBHUB_DB_PASSWORD
```

The password is entered interactively and exported only for the active shell session.

The Ansible container task uses:

```text
no_log: true
```

to avoid exposing sensitive runtime values in execution output.

---

# Application Endpoints

The BobHub OCI application now exposes:

```text
/
```

```text
/health
```

```text
/whoami
```

```text
/db-health
```

## Application Health

```text
GET /health
```

Response:

```text
healthy
```

This endpoint remains independent from Azure PostgreSQL.

It is used by the OCI Load Balancer health checker.

A database outage therefore does not automatically make the regional application instance unhealthy.

---

## Cloud Identity

```text
GET /whoami
```

Validated response:

```text
cloud=oci
hostname=app01
private_ip=10.40.20.203
version=v0.3.0
```

---

## Database Health

```text
GET /db-health
```

Validated response:

```text
database=azure-postgresql
status=healthy
cloud=oci
```

This endpoint performs a real PostgreSQL connection and query before returning a healthy status.

The application connects using:

```text
bobhub_app
```

and:

```text
sslmode=verify-full
```

---

# External End-to-End Validation

The final public path was validated through the OCI public application entry.

```text
Internet
   ↓
OCI WAF
   ↓
OCI Load Balancer
   ↓
Traefik
   ↓
BobHub Application
   ↓
Azure PostgreSQL
```

The following public endpoints returned successfully:

```text
/health
→ healthy
```

```text
/whoami
→ OCI application identity
```

```text
/db-health
→ Azure PostgreSQL healthy
```

This confirms that Azure PostgreSQL connectivity works through the complete application path rather than only from an administrative shell.

---

# OCI WAF Validation

The existing permanent BobHub WAF validation rule remained functional after the application migration.

Validation request header:

```text
x-bobhub-waf-test: block
```

Result:

```text
HTTP/1.1 403 Forbidden
```

Response body:

```text
BobHub WAF test blocked
```

This proves that the application changes did not bypass or break the existing WAF enforcement layer.

---

# OCI Load Balancer

The existing OCI Flexible Load Balancer continues to route traffic to the private application instance.

Health checker:

```text
Protocol: HTTP
Port: 80
Path: /health
Expected response: 200
```

The database health endpoint is intentionally not used as the Load Balancer health check.

This preserves separation between:

```text
Application health
```

and:

```text
Database dependency health
```

---

# Terraform Drift Validation

Final validation was executed independently in both Terraform roots.

Azure:

```text
terraform fmt -check
terraform validate
terraform plan
```

Result:

```text
No changes.
Your infrastructure matches the configuration.
```

OCI:

```text
terraform fmt -check
terraform validate
terraform plan
```

Result:

```text
No changes.
Your infrastructure matches the configuration.
```

This confirms that the final cross-cloud environment is fully represented by the intended Terraform configuration without unintended drift.

---

# Functional Result

Before this delivery:

```text
Internet
   ↓
OCI WAF
   ↓
OCI Load Balancer
   ↓
OCI Application
```

After this delivery:

```text
Internet
   ↓
OCI WAF
   ↓
OCI Load Balancer
   ↓
OCI Application
   ↓
Azure PostgreSQL
```

Validated:

```text
OCI private workload
→ Azure PostgreSQL DNS

OCI private workload
→ Azure PostgreSQL TCP 5432

OCI private workload
→ TLS verify-full

OCI private workload
→ bobhub_app authentication

OCI private workload
→ SELECT

OCI private workload
→ INSERT

OCI application
→ /db-health

Internet
→ OCI WAF
→ OCI Load Balancer
→ OCI application
→ Azure PostgreSQL
```

---

# Learning Outcomes

This delivery introduced practical experience with:

```text
Azure infrastructure
Azure PostgreSQL Flexible Server
Terraform multi-cloud state separation
Cross-cloud application dependencies
Public database endpoint hardening
Cloud firewall rules
NAT egress addressing
PostgreSQL administration
PostgreSQL least privilege
TLS certificate validation
Application database integration
Python application containers
Flask
Gunicorn
psycopg
Ansible runtime configuration
Secret handling
Application health design
Infrastructure lifecycle validation
```

A key architectural lesson from this lab was the distinction between:

```text
Application health
→ /health

Dependency health
→ /db-health
```

The Load Balancer should not automatically remove an application instance only because an external dependency is temporarily unavailable.

---

# Final State

Issue #59 establishes the first real shared cross-cloud application dependency in BobHub v0.3.0.

Current architecture:

```text
OCI
 ↓
BobHub Application
 ↓
Azure PostgreSQL
```

The Azure database is now prepared to become the shared data layer for the future AWS primary environment:

```text
AWS ──┐
      ├──→ Azure PostgreSQL
OCI ──┘
```

The next multi-cloud application phase can reuse the same PostgreSQL data layer to validate application portability, failover and disaster recovery scenarios.