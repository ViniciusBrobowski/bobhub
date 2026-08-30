# BobHub v0.3.0 — OCI Compute, Ansible & Application Baseline

## Status

Completed.

## Version

BobHub v0.3.0 — Multi-Cloud IaC, Security & Resilience

## Related Issue

GitHub Issue #55 — Provision BobHub v0.3.0 OCI compute and application baseline

---

# Overview

This document records the final implemented OCI application baseline for BobHub v0.3.0.

The objective of this delivery was to move beyond the OCI network foundation and provision a functional private workload prepared for the future OCI Load Balancer and WAF layers.

The implementation validates:

- OCI Compute provisioning through Terraform
- Private subnet workload design
- OCI Bastion administrative access
- Private Internet egress through NAT Gateway
- Ansible configuration management
- Docker runtime deployment
- Traefik application routing
- Stateless BobHub application endpoints
- Terraform lifecycle validation
- Ansible idempotency

The final design intentionally separates infrastructure provisioning from operating system and application configuration.

---

# Final Architecture

The implemented OCI baseline is:

```text
Local Workstation
        |
        v
OCI Bastion
        |
        v
Private Application Subnet
10.40.20.0/24
        |
        v
OCI Compute
Ubuntu 24.04 ARM64
        |
        v
Ansible
        |
        v
Docker
        |
        v
Traefik :80
        |
        v
BobHub Application
        |
        +-- /
        +-- /health
        +-- /whoami
```

The application compute instance does not receive a public IP.

Administrative access is performed through OCI Bastion.

Private outbound Internet access is provided through an OCI NAT Gateway.

---

# Responsibility Separation

The final implementation follows this model:

```text
Terraform
Infrastructure as Code
        |
        +-- VCN
        +-- Subnets
        +-- Route Tables
        +-- Internet Gateway
        +-- NAT Gateway
        +-- Security Lists
        +-- Network Security Group
        +-- OCI Bastion
        +-- Compute
        |
        v
Ansible
Configuration as Code
        |
        +-- Operating system packages
        +-- Docker
        +-- Docker network
        +-- Traefik
        +-- BobHub Application
        |
        v
Docker
Application Runtime
        |
        v
Traefik
Application Routing
```

In practical terms:

```text
Terraform
→ defines that infrastructure must exist

Ansible
→ defines how the server must be configured

Docker
→ runs the application workload

Traefik
→ routes application traffic
```

---

# Terraform Infrastructure

The OCI lifecycle remains isolated under:

```text
terraform/multicloud/oci-dr/
```

The Terraform implementation manages:

- OCI VCN
- Public subnet
- Private application subnet
- Public route table
- Application route table
- Internet Gateway
- NAT Gateway
- Public Security List
- Application Security List
- Application Network Security Group
- OCI Bastion
- OCI Compute instance
- Terraform outputs

Terraform state remains independent in the OCI HCP Terraform workspace.

The application instance is provisioned entirely through Terraform.

---

# Compute Baseline

The application workload currently uses:

```text
Cloud: Oracle Cloud Infrastructure
Region: sa-vinhedo-1
Shape: VM.Standard.A1.Flex
Architecture: ARM64
OCPU: 1
Memory: 6 GB
OS: Canonical Ubuntu 24.04
Subnet: 10.40.20.0/24
Public IP: disabled
```

The Ubuntu image is dynamically discovered through Terraform.

The image OCID is not hardcoded.

Conceptually:

```text
Terraform
    |
    v
Query OCI Images
    |
    v
Latest compatible Ubuntu 24.04 ARM64 image
    |
    v
OCI Compute
```

---

# Private Application Subnet

The OCI application workload is deployed inside:

```text
10.40.20.0/24
```

The subnet is private.

The application Compute instance does not receive a public IP.

This prevents direct Internet access to the workload.

The current architecture is designed so that future public application traffic will enter through controlled OCI services rather than directly reaching the Compute instance.

---

# Private Internet Egress

The private application subnet requires outbound access for:

- Ubuntu package updates
- package installation
- Docker image downloads
- external dependencies required during configuration

Outbound access is provided through an OCI NAT Gateway.

```text
OCI Compute
     |
     v
Application Route Table
     |
     v
OCI NAT Gateway
     |
     v
Internet
```

The application subnet route table contains a default route:

```text
0.0.0.0/0
```

using the NAT Gateway as the network entity.

This provides outbound connectivity while keeping the instance private.

Validated operations included:

```bash
sudo apt update
```

and external HTTP connectivity.

---

# OCI Bastion

SSH is not exposed directly to the public Internet.

OCI Bastion provides the controlled administrative access path.

Conceptually:

```text
Local Workstation
        |
        v
OCI Bastion Session
        |
        v
Private Compute :22
```

The Bastion service is managed through Terraform.

Bastion sessions are temporary operational resources created when administrative access is required.

The application Network Security Group allows SSH only from the Bastion private endpoint.

---

# Bastion SSH Tunnel

Because the Compute instance is private, a local SSH tunnel is created through OCI Bastion.

Example conceptual flow:

```text
WSL
 |
 | 127.0.0.1:2222
 v
SSH Local Port Forward
 |
 v
OCI Bastion
 |
 v
OCI Compute :22
```

Example tunnel command structure:

```bash
ssh \
  -i ~/.ssh/bobhub-oci \
  -N \
  -L 2222:<APPLICATION_PRIVATE_IP>:22 \
  -p 22 \
  <BASTION_SESSION_OCID>@host.bastion.sa-vinhedo-1.oci.oraclecloud.com
```

The Bastion session OCID must begin with:

```text
ocid1.bastionsession...
```

and not:

```text
ocid1.bastion...
```

The tunnel remains open while administrative access or Ansible execution is required.

---

# SSH Host Key Behavior

Because the application VM is disposable and may be recreated through Terraform, the SSH host key changes when the instance is replaced.

When this happens, the existing local entry can be removed using:

```bash
ssh-keygen \
  -f "/home/brobowski/.ssh/known_hosts" \
  -R "[127.0.0.1]:2222"
```

The new host key can then be accepted on the next SSH connection.

This behavior is expected after intentional Terraform replacement of the Compute instance.

---

# Ansible Controller

Ansible runs from Ubuntu through WSL.

The controller path is:

```text
Windows
    |
    v
WSL Ubuntu
    |
    v
Ansible
```

The SSH private key is stored outside the repository:

```text
/home/brobowski/.ssh/bobhub-oci
```

Permissions:

```bash
chmod 600 ~/.ssh/bobhub-oci
```

The private SSH key is never committed to Git.

---

# Ansible Structure

The Ansible implementation is located under:

```text
ansible/
├── inventory/
│   └── oci.ini
└── playbooks/
    └── oci-application.yml
```

The inventory uses the local Bastion tunnel.

Example:

```ini
[oci_app]
bobhub-oci ansible_host=127.0.0.1 ansible_port=2222 ansible_user=ubuntu ansible_ssh_private_key_file=/home/brobowski/.ssh/bobhub-oci
```

This means Ansible does not require direct connectivity to the OCI private network.

Conceptually:

```text
Ansible
    |
    v
127.0.0.1:2222
    |
    v
OCI Bastion
    |
    v
Private Compute
```

---

# Ansible Connectivity Validation

Connectivity was validated using:

```bash
ansible \
  -i ansible/inventory/oci.ini \
  oci_app \
  -m ping
```

Successful result:

```text
bobhub-oci | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

This confirmed:

```text
WSL
  ↓
Ansible
  ↓
SSH Tunnel
  ↓
OCI Bastion
  ↓
Private OCI Compute
  ↓
Python 3
```

---

# Ansible Application Playbook

The main application playbook is:

```text
ansible/playbooks/oci-application.yml
```

The playbook is responsible for:

- updating the APT cache
- installing Docker
- installing curl
- installing Python Docker dependencies
- enabling Docker
- adding the Ubuntu user to the Docker group
- creating the application directories
- creating `/health`
- creating `/whoami`
- creating the Nginx configuration
- creating the Docker network
- deploying Traefik
- deploying the BobHub application

Execution:

```bash
ansible-playbook \
  -i ansible/inventory/oci.ini \
  ansible/playbooks/oci-application.yml
```

---

# Cloud-init Migration

During the initial implementation, cloud-init was used to:

- install Docker
- create application files
- start the BobHub application container

This worked successfully as an initial bootstrap mechanism.

As the application configuration evolved, the configuration responsibilities became larger.

The design was therefore changed from:

```text
Terraform
    |
    v
cloud-init
    |
    +-- Docker
    +-- Nginx
    +-- BobHub Application
```

to:

```text
Terraform
    |
    v
OCI Infrastructure
    |
    v
Ansible
    |
    +-- Docker
    +-- Traefik
    +-- BobHub Application
```

The application cloud-init configuration was removed from the final Terraform implementation.

Terraform now provides only the SSH authorized key in instance metadata.

Example:

```hcl
metadata = {
  ssh_authorized_keys = file(var.ssh_public_key_path)
}
```

This keeps infrastructure provisioning and configuration management clearly separated.

---

# Clean VM Validation

The Compute instance was intentionally replaced after removing the application cloud-init configuration.

The resulting lifecycle was:

```text
terraform apply
      |
      v
New OCI Compute
      |
      | no Docker application bootstrap
      v
OCI Bastion
      |
      v
Ansible
      |
      +-- Docker
      +-- Traefik
      +-- BobHub Application
```

The clean VM was successfully configured entirely through Ansible.

This validated that the workload does not depend on manual configuration or the previous cloud-init implementation.

---

# Docker Runtime

Ansible installs and manages Docker.

A dedicated Docker network is created:

```text
bobhub
```

The current runtime contains:

```text
traefik
bobhub-app
```

Validated through:

```bash
docker ps
```

Expected structure:

```text
traefik
→ publishes host port 80

bobhub-app
→ internal port 80 only
```

Example conceptual output:

```text
traefik      0.0.0.0:80->80/tcp
bobhub-app   80/tcp
```

---

# Docker Network Architecture

The final container topology is:

```text
Host :80
   |
   v
Traefik
   |
   | Docker network: bobhub
   v
bobhub-app
   |
   v
Nginx :80
```

The BobHub application container does not publish a port directly to the host.

This means:

```text
Host → bobhub-app directly
```

is not the intended traffic path.

Instead:

```text
Host
 ↓
Traefik
 ↓
bobhub-app
```

Traefik becomes the application entry point inside the Compute instance.

---

# Traefik

Traefik is deployed as a Docker container.

Current image:

```text
traefik:v3
```

Current entrypoint:

```text
web :80
```

Traefik uses the Docker provider.

Configuration includes:

```text
providers.docker=true
providers.docker.exposedbydefault=false
entrypoints.web.address=:80
```

The Docker socket is mounted read-only:

```text
/var/run/docker.sock:/var/run/docker.sock:ro
```

The application is explicitly exposed through Docker labels.

Conceptually:

```text
HTTP Request
     |
     v
Traefik :80
     |
     v
Docker Provider
     |
     v
Container Labels
     |
     v
bobhub-app :80
```

---

# Traefik Application Routing

The application container contains labels similar to:

```text
traefik.enable=true
traefik.http.routers.bobhub.rule=PathPrefix(`/`)
traefik.http.routers.bobhub.entrypoints=web
traefik.http.services.bobhub.loadbalancer.server.port=80
```

The `PathPrefix("/")` rule routes the application traffic to the BobHub application container.

---

# BobHub Demo Application

The BobHub application is a small stateless Nginx-based workload.

It provides three endpoints.

## Root

Endpoint:

```text
/
```

Response:

```text
BobHub OCI Application
```

---

## Health

Endpoint:

```text
/health
```

Response:

```text
healthy
```

The endpoint returns:

```text
HTTP 200
Content-Type: text/plain
```

This endpoint is intended to be used later by:

- OCI Load Balancer health checks
- monitoring
- failover validation
- availability tests

---

## Whoami

Endpoint:

```text
/whoami
```

Example response:

```text
cloud=oci
hostname=app01
private_ip=<APPLICATION_PRIVATE_IP>
version=v0.3.0
```

This endpoint provides runtime identity information.

It will be useful during the future multi-cloud implementation to identify which cloud environment is serving a request.

---

# Application Validation

The application was validated directly from the OCI Compute instance.

Commands:

```bash
curl -i http://localhost/
curl -i http://localhost/health
curl -i http://localhost/whoami
```

Expected results:

```text
/         → HTTP 200
/health   → HTTP 200
/whoami   → HTTP 200
```

Validated responses included:

```text
BobHub OCI Application
```

```text
healthy
```

and:

```text
cloud=oci
hostname=app01
private_ip=<APPLICATION_PRIVATE_IP>
version=v0.3.0
```

---

# Browser Access Before Load Balancer

The application Compute instance remains private.

Before the OCI Load Balancer exists, browser access is provided through another SSH port-forwarding tunnel.

This creates a second tunnel on top of the Bastion SSH tunnel.

Application tunnel:

```bash
ssh \
  -i ~/.ssh/bobhub-oci \
  -p 2222 \
  -N \
  -L 8080:127.0.0.1:80 \
  ubuntu@127.0.0.1
```

This tunnel exposes:

```text
127.0.0.1:8080
```

locally and forwards traffic to:

```text
OCI Compute :80
```

through the existing SSH connection path.

---

# Nested SSH Tunnel Flow

The complete access path is:

```text
Browser
   |
   | localhost:8080
   v
Application SSH Tunnel
   |
   | localhost:2222
   v
Bastion SSH Tunnel
   |
   v
OCI Bastion
   |
   v
OCI Compute :22
   |
   v
OCI Compute :80
   |
   v
Traefik
   |
   v
bobhub-app
```

Operationally:

```text
Terminal 1
→ OCI Bastion tunnel

Terminal 2
→ Application port tunnel

Terminal 3
→ Ansible / SSH / operational commands
```

The browser can then access:

```text
http://127.0.0.1:8080/
```

```text
http://127.0.0.1:8080/health
```

```text
http://127.0.0.1:8080/whoami
```

This is a temporary laboratory access mechanism.

The future OCI Load Balancer will eliminate the need for this application tunnel during normal access.

---

# Ansible Idempotency Validation

After the clean OCI instance was configured, the Ansible playbook was executed again.

The second execution completed successfully without unintended configuration changes.

Desired result:

```text
changed=0
failed=0
```

This demonstrates Ansible idempotency.

Conceptually:

```text
Desired state already configured
          |
          v
Run Ansible again
          |
          v
No unnecessary modifications
```

This confirms that the configuration can be safely applied repeatedly.

---

# Terraform Lifecycle Validation

The Compute workload was recreated multiple times during implementation.

Terraform successfully handled instance replacement while preserving the surrounding OCI infrastructure.

The final lifecycle was validated as:

```text
Terraform Configuration
        |
        v
terraform apply
        |
        v
OCI Compute
        |
        v
Bastion Access
        |
        v
Ansible Configuration
        |
        v
Functional Application
```

After the final infrastructure configuration:

```bash
terraform plan
```

returned:

```text
No changes. Your infrastructure matches the configuration.
```

This confirms that the Terraform-managed OCI infrastructure matches the declared desired state.

---

# Terraform and Ansible Idempotency

The final baseline validates both infrastructure and configuration state.

```text
Terraform
terraform plan
      |
      v
No changes
```

and:

```text
Ansible
ansible-playbook
      |
      v
changed=0
failed=0
```

Together this validates:

```text
Infrastructure as Code
+
Configuration as Code
```

---

# Security Baseline

The final implementation follows these principles:

- application Compute has no public IP
- SSH is not exposed directly to the Internet
- OCI Bastion provides administrative access
- application subnet remains private
- NAT Gateway provides outbound Internet access
- SSH private key remains outside Git
- Terraform state remains remote
- environment-specific `terraform.tfvars` remains outside Git
- application container does not directly publish a host port
- Traefik is the application entry point
- additional Traefik management interfaces are not publicly exposed
- Bastion sessions are temporary
- security rules follow least-exposure principles

---

# Repository Security

Sensitive files are not intentionally committed.

The repository excludes:

```text
terraform.tfvars
*.tfstate
*.tfstate.*
.terraform/
```

SSH private keys are stored outside the repository.

Only sanitized configuration examples should be versioned.

---

# Validated Operational Flow

The current workflow is:

```text
terraform apply
      |
      v
OCI Infrastructure
      |
      v
Private Compute
      |
      v
Create OCI Bastion Session
      |
      v
Create local SSH tunnel
      |
      v
Ansible ping
      |
      v
ansible-playbook
      |
      v
Docker
      |
      v
Traefik
      |
      v
BobHub Application
```

Validation:

```bash
ansible \
  -i ansible/inventory/oci.ini \
  oci_app \
  -m ping
```

```bash
ansible-playbook \
  -i ansible/inventory/oci.ini \
  ansible/playbooks/oci-application.yml
```

```bash
curl -i http://localhost/
curl -i http://localhost/health
curl -i http://localhost/whoami
```

---

# Lifecycle Reproducibility

The OCI application workload is disposable.

The intended lifecycle is:

```text
terraform destroy
      |
      v
OCI Infrastructure Removed
```

and later:

```text
terraform apply
      |
      v
OCI Infrastructure Recreated
      |
      v
Bastion Access
      |
      v
Ansible
      |
      v
Application Restored
```

The workload does not depend on manual configuration stored inside the instance.

---

# FinOps Considerations

The OCI environment follows the BobHub v0.3.0 FinOps strategy.

Principles:

```text
Target out-of-pocket cost: US$ 0

Free / Always Free resources
→ preferred

Paid persistent resources
→ avoid when possible

Temporary learning resources
→ destroy when no longer required
```

The NAT Gateway and other potentially billable resources must remain part of the explicit cost-awareness strategy.

Credits are treated as budget capacity, not permission to leave unnecessary infrastructure running.

---

# Issue #55 Acceptance Criteria

The following acceptance criteria were completed:

- OCI Compute workload provisioned through Terraform
- workload deployed in private application subnet `10.40.20.0/24`
- workload has no public IP
- OCI Bastion administrative access implemented
- SSH not exposed directly to the Internet
- private outbound connectivity implemented through NAT Gateway
- Docker successfully installed
- Ansible introduced for configuration management
- clean VM configured through Ansible
- Docker network created
- Traefik deployed
- BobHub demo application containerized
- `/health` validated
- `/whoami` validated
- application routing through Traefik validated
- browser access through SSH forwarding validated
- Ansible idempotency validated
- Terraform lifecycle validated
- final Terraform plan reports no unintended changes
- environment ready for OCI Load Balancer and WAF

---

# Result

Issue #55 establishes the first functional OCI application workload for BobHub v0.3.0.

The delivery demonstrates practical knowledge of:

- Terraform
- OCI Compute
- OCI networking
- private subnet architecture
- NAT Gateway
- OCI Bastion
- SSH port forwarding
- network security
- Infrastructure as Code
- Ansible
- configuration management
- idempotency
- Docker
- Docker networking
- Traefik
- reverse proxy concepts
- application routing
- health checks
- lifecycle validation
- security responsibility separation
- FinOps

---

# Final Validated Flow

```text
Terraform
   |
   v
OCI Infrastructure
   |
   v
Private Compute
   |
   v
OCI Bastion
   |
   v
Ansible
   |
   v
Docker
   |
   v
Traefik
   |
   v
BobHub Application
   |
   +-- /
   +-- /health
   +-- /whoami
```

---

# Current State

The OCI backend is operational but intentionally private.

Current application access:

```text
Browser
   |
   v
SSH forwarding
   |
   v
OCI Bastion
   |
   v
Traefik
   |
   v
BobHub App
```

The Compute workload itself does not act as an Internet-facing endpoint.

---

# Next Step

The OCI application backend is now ready for the next BobHub v0.3.0 learning delivery.

Target:

```text
Internet
   |
   v
OCI WAF
   |
   v
OCI Load Balancer
   |
   v
Traefik
   |
   v
BobHub Application
```

The next stage will introduce:

- OCI Load Balancer
- backend sets
- health checks
- controlled public application ingress
- integration with the existing private application subnet
- OCI WAF
- WAF policies and rules
- validation of the complete public request path

This will replace SSH forwarding as the normal application access mechanism while preserving the private Compute architecture.