# BobHub v0.3.0 — OCI Load Balancer and WAF Checkpoint

## Overview

This checkpoint documents the implementation and validation of the public OCI application entry layer for BobHub v0.3.0.

The delivery was tracked through GitHub Issue:

```text
#57 — Provision OCI Load Balancer and WAF application entry
```

The objective was to expose the existing private OCI application through a controlled public entry point while keeping the Compute instance private.

The implementation introduced:

```text
OCI Web Application Firewall
OCI Flexible Load Balancer
HTTP Listener
Backend Set
Private Compute Backend
Health Check
Terraform management
```

The final application path is:

```text
Internet
   ↓
OCI WAF
   ↓
OCI Load Balancer
   ↓
Listener HTTP :80
   ↓
Backend Set
   ↓
Private Compute :80
   ↓
Traefik
   ↓
BobHub Application
```

---

# Learning Strategy

The implementation was intentionally performed manually before being consolidated into Terraform.

The sequence was:

```text
Existing private BobHub backend
        ↓
Understand OCI Load Balancer
        ↓
Create Load Balancer manually
        ↓
Validate application traffic
        ↓
Understand OCI WAF
        ↓
Create WAF policy manually
        ↓
Validate allow/block behavior
        ↓
Describe resources in Terraform
        ↓
Import existing resources
        ↓
Remove Terraform drift
        ↓
Validate Terraform lifecycle
```

This approach allowed the individual OCI components to be understood before introducing Infrastructure as Code.

The main conceptual distinction used during the lab was:

```text
Load Balancer
→ WHERE the request goes

WAF
→ WHETHER the request may pass
```

---

# Previous Application Baseline

The infrastructure created in the previous OCI application checkpoint already provided:

```text
Private OCI Compute
        ↓
Ansible
        ↓
Docker
        ↓
Traefik
        ↓
BobHub Application
```

The application exposes:

```text
/
```

```text
/health
```

```text
/whoami
```

Example application responses:

```text
/
→ BobHub OCI Application
```

```text
/health
→ healthy
```

```text
/whoami
→ cloud=oci
   hostname=app01
   private_ip=<private-ip>
   version=v0.3.0
```

The Compute instance remains inside the private application subnet:

```text
10.40.20.0/24
```

The instance has no public IP.

Administrative access continues to use OCI Bastion.

Outbound access continues to use the OCI NAT Gateway.

---

# Network Architecture

The OCI network remains separated into public and private layers.

```text
BobHub OCI VCN
10.40.0.0/16
```

Public subnet:

```text
10.40.10.0/24
```

Application subnet:

```text
10.40.20.0/24
```

The public Load Balancer runs in the public subnet.

The application Compute instance runs in the private application subnet.

Final flow:

```text
Internet
   |
   v
Public OCI Load Balancer
10.40.10.0/24
   |
   v
Private Application Subnet
10.40.20.0/24
   |
   v
Compute
   |
   v
Traefik :80
   |
   v
BobHub Application
```

The Compute instance never receives a public IP.

---

# OCI Load Balancer

A Flexible Load Balancer was created.

Resource name:

```text
bobhub-v03-oci-lb
```

Configuration:

```text
Visibility:
Public

Shape:
Flexible

Minimum bandwidth:
10 Mbps

Maximum bandwidth:
10 Mbps

IP mode:
IPv4

Public IP:
Ephemeral

Subnet:
bobhub-v03-public-subnet
```

The Load Balancer provides the public application entry point.

---

# Load Balancer Listener

An HTTP listener was created.

```text
Name:
bobhub-http-80

Protocol:
HTTP

Port:
80
```

The initial implementation intentionally uses HTTP.

TLS termination was not introduced during this stage so that Load Balancer behavior could be understood without mixing certificate and HTTPS configuration into the first validation.

The listener forwards traffic to the application backend set.

---

# Backend Set

The Load Balancer backend set was configured using:

```text
Policy:
Weighted Round Robin
```

Terraform represents the policy as:

```text
ROUND_ROBIN
```

Backend Set:

```text
bs_lb_2026-0830-1700
```

The backend set contains the private OCI Compute instance.

Conceptually:

```text
Listener
   ↓
Backend Set
   ↓
Backend
```

The backend set also defines the health check used to determine whether the application is available.

---

# Backend

The backend is the private OCI application Compute instance.

```text
Backend:
Private Compute

Port:
80
```

Example private address during validation:

```text
10.40.20.80
```

The IP is dynamically obtained by Terraform from:

```hcl
oci_core_instance.application.private_ip
```

The backend does not expose a public IP.

Traffic reaches the application through:

```text
Load Balancer
        ↓
Compute private IP :80
        ↓
Traefik
        ↓
bobhub-app
```

---

# Health Check

The Load Balancer health checker uses:

```text
Protocol:
HTTP

Port:
80

Path:
/health

Expected status:
200

Interval:
10000 ms

Timeout:
3000 ms

Retries:
3
```

The health check validates more than the Compute instance itself.

It verifies the effective application path:

```text
Load Balancer
   ↓
Compute networking
   ↓
Docker
   ↓
Traefik
   ↓
BobHub application
   ↓
/health
```

Expected response:

```text
HTTP 200
healthy
```

The backend reached:

```text
Health: OK
```

---

# Request ID

OCI Load Balancer request IDs were enabled.

Configuration:

```text
Request ID:
Enabled

Header:
X-Request-Id
```

Example response:

```text
HTTP/1.1 200 OK
X-Request-Id: b47126d8a879cac796ca97ca4eaa4c57
```

This provides a request identifier that can later be used for troubleshooting and observability.

---

# Logging

OCI Load Balancer access and error logging were intentionally left disabled during this lab.

Configuration:

```text
Error logs:
Disabled

Access logs:
Disabled
```

The goal was to avoid unnecessary persistent logging costs while the application entry path was being validated.

Logging can be introduced later when required for observability or troubleshooting.

---

# Load Balancer Validation

The Load Balancer was validated directly through its public address.

Root endpoint:

```powershell
curl.exe http://<LOAD_BALANCER_PUBLIC_IP>/
```

Result:

```text
BobHub OCI Application
```

Health endpoint:

```powershell
curl.exe http://<LOAD_BALANCER_PUBLIC_IP>/health
```

Result:

```text
healthy
```

Whoami endpoint:

```powershell
curl.exe http://<LOAD_BALANCER_PUBLIC_IP>/whoami
```

Result:

```text
cloud=oci
hostname=app01
private_ip=10.40.20.80
version=v0.3.0
```

Header validation:

```powershell
curl.exe -i http://<LOAD_BALANCER_PUBLIC_IP>/health
```

Example result:

```text
HTTP/1.1 200 OK
Content-Type: text/plain
X-Request-Id: <request-id>

healthy
```

This confirmed:

```text
Internet
   ↓
OCI Load Balancer
   ↓
Listener
   ↓
Backend Set
   ↓
Private Compute
   ↓
Traefik
   ↓
BobHub Application
```

The previous SSH application tunnel was no longer required for normal application access.

---

# OCI Web Application Firewall

After validating the Load Balancer, OCI WAF was introduced.

Policy:

```text
bobhub-v03-oci-waf-policy
```

Firewall:

```text
bobhub-v03-oci-waf
```

Enforcement point:

```text
OCI Load Balancer
```

Final path:

```text
Internet
   ↓
OCI WAF
   ↓
OCI Load Balancer
   ↓
Private Backend
```

The WAF policy controls whether a request is allowed to reach the Load Balancer backend path.

---

# WAF Actions

The policy contains the OCI pre-configured actions:

```text
Pre-configured Check Action
Pre-configured Allow Action
Pre-configured 401 Response Code Action
```

A custom action was also created:

```text
bobhub-test-block
```

Configuration:

```text
Type:
RETURN_HTTP_RESPONSE

HTTP status:
403

Response:
BobHub WAF test blocked
```

The action terminates the request at the WAF layer instead of forwarding it to the application backend.

---

# WAF Access Rule

A controlled test rule was created.

Rule:

```text
bobhub-block-test-header
```

Condition:

```text
http.request.headers."x-bobhub-waf-test"[0] == 'block'
```

Condition language:

```text
JMESPATH
```

Action:

```text
bobhub-test-block
```

The test header is:

```text
X-BobHub-WAF-Test: block
```

Behavior:

```text
Normal request
        ↓
OCI WAF
        ↓
Allow
        ↓
OCI Load Balancer
        ↓
Application
```

Test request:

```text
X-BobHub-WAF-Test: block
        ↓
OCI WAF
        ↓
bobhub-block-test-header
        ↓
bobhub-test-block
        ↓
HTTP 403
```

---

# WAF Validation

Normal request:

```powershell
curl.exe -i http://<LOAD_BALANCER_PUBLIC_IP>/health
```

Result:

```text
HTTP/1.1 200 OK

healthy
```

Blocked request:

```powershell
curl.exe -i -H "X-BobHub-WAF-Test: block" http://<LOAD_BALANCER_PUBLIC_IP>/health
```

Result:

```text
HTTP/1.1 403 Forbidden

BobHub WAF test blocked
```

This proved that the WAF evaluates the request before application traffic reaches the backend.

---

# Terraform Integration

After the manual implementation was validated, the infrastructure was described in Terraform.

Terraform root:

```text
terraform/multicloud/oci-dr/
```

New files:

```text
load-balancer.tf
waf.tf
```

Responsibility remains:

```text
Terraform
→ OCI infrastructure

Ansible
→ Compute operating system
→ Docker
→ Traefik
→ Application configuration
```

---

# Terraform Load Balancer Resources

Terraform now manages:

```text
oci_load_balancer_load_balancer.bobhub
oci_load_balancer_backend_set.application
oci_load_balancer_backend.application
oci_load_balancer_listener.http
```

The Load Balancer configuration references existing Terraform-managed resources.

Example:

```hcl
subnet_ids = [
  oci_core_subnet.public.id
]
```

Backend IP:

```hcl
ip_address = oci_core_instance.application.private_ip
```

This avoids hardcoded private application addresses.

---

# Terraform WAF Resources

Terraform now manages:

```text
oci_waf_web_app_firewall_policy.bobhub
oci_waf_web_app_firewall.bobhub
```

The WAF firewall references the Load Balancer:

```hcl
load_balancer_id = oci_load_balancer_load_balancer.bobhub.id
```

The policy is attached through:

```hcl
web_app_firewall_policy_id = oci_waf_web_app_firewall_policy.bobhub.id
```

---

# Terraform Import Strategy

Because the Load Balancer and WAF were created manually for learning purposes, they already existed before Terraform management was introduced.

The resources were therefore imported rather than recreated.

Sequence:

```text
Manual OCI resource
        ↓
Terraform configuration
        ↓
terraform import
        ↓
HCP Terraform state
        ↓
terraform plan
        ↓
No changes
```

This preserved the manually validated infrastructure while transitioning ownership to Terraform.

---

# Load Balancer Import

The parent Load Balancer was imported first.

```powershell
terraform import oci_load_balancer_load_balancer.bobhub "<LOAD_BALANCER_OCID>"
```

After import:

```powershell
terraform state show oci_load_balancer_load_balancer.bobhub
```

The imported state revealed OCI-generated attributes including:

```text
is_request_id_enabled = true
request_id_header     = "X-Request-Id"
```

The Terraform configuration was updated to represent these values exactly.

---

# Backend Set Import

The Backend Set was imported using its composite OCI resource ID.

```powershell
terraform import oci_load_balancer_backend_set.application "loadBalancers/<LOAD_BALANCER_OCID>/backendSets/bs_lb_2026-0830-1700"
```

---

# Backend Import

The backend was imported using the Load Balancer, Backend Set and backend name.

```powershell
terraform import oci_load_balancer_backend.application "loadBalancers/<LOAD_BALANCER_OCID>/backendSets/bs_lb_2026-0830-1700/backends/<PRIVATE_IP>:80"
```

---

# Listener Import

The listener was imported using:

```powershell
terraform import oci_load_balancer_listener.http "loadBalancers/<LOAD_BALANCER_OCID>/listeners/bobhub-http-80"
```

---

# Load Balancer Terraform State

Validation:

```powershell
terraform state list | Select-String "load_balancer"
```

Result:

```text
oci_load_balancer_backend.application
oci_load_balancer_backend_set.application
oci_load_balancer_listener.http
oci_load_balancer_load_balancer.bobhub
```

After correcting the exact capitalization of:

```text
X-Request-Id
```

Terraform reached:

```text
No changes. Your infrastructure matches the configuration.
```

---

# WAF Import

The manually created WAF Policy was imported:

```powershell
terraform import oci_waf_web_app_firewall_policy.bobhub "<WAF_POLICY_OCID>"
```

The imported state showed the complete policy configuration, including:

```text
Pre-configured actions
Custom 403 action
Request access control
JMESPath condition
```

This information was then used to reproduce the policy exactly in Terraform.

---

# WAF Firewall Import

The WAF Firewall enforcement point was imported using:

```powershell
terraform import oci_waf_web_app_firewall.bobhub "<WAF_FIREWALL_OCID>"
```

After both resources were imported:

```powershell
terraform state list | Select-String "waf"
```

Expected resources:

```text
oci_waf_web_app_firewall.bobhub
oci_waf_web_app_firewall_policy.bobhub
```

Final validation:

```powershell
terraform plan
```

Result:

```text
No changes. Your infrastructure matches the configuration.
```

---

# Terraform Lifecycle Validation

A temporary WAF rule was created directly through Terraform to prove that Terraform was not only tracking imported infrastructure but could actively modify OCI behavior.

Temporary action:

```text
bobhub-terraform-validation-block
```

Temporary header:

```text
X-BobHub-Terraform-Test: block
```

Temporary response:

```text
HTTP 403

BobHub Terraform validation blocked
```

The lifecycle test was:

```text
Terraform code modified
        ↓
terraform plan
        ↓
terraform apply
        ↓
OCI WAF updated
        ↓
Request blocked
```

After validation, the temporary action and rule were removed from Terraform.

Another apply returned the WAF policy to the original baseline.

---

# Terraform Lifecycle Test — Create

The temporary rule was applied.

Test:

```powershell
curl.exe -i -H "X-BobHub-Terraform-Test: block" http://<LOAD_BALANCER_PUBLIC_IP>/health
```

Expected result while the Terraform validation rule existed:

```text
HTTP/1.1 403 Forbidden

BobHub Terraform validation blocked
```

This confirmed that Terraform successfully modified WAF behavior.

---

# Terraform Lifecycle Test — Remove

The temporary Terraform validation rule was removed from `waf.tf`.

Terraform was applied again.

The same request was repeated:

```powershell
curl.exe -i -H "X-BobHub-Terraform-Test: block" http://<LOAD_BALANCER_PUBLIC_IP>/health
```

Result:

```text
HTTP/1.1 200 OK

healthy
```

This confirmed that Terraform successfully removed the temporary WAF behavior.

---

# Permanent WAF Rule Validation

After removing the temporary Terraform test, the original WAF rule remained active.

Validation:

```powershell
curl.exe -i -H "X-BobHub-WAF-Test: block" http://<LOAD_BALANCER_PUBLIC_IP>/health
```

Expected result:

```text
HTTP/1.1 403 Forbidden

BobHub WAF test blocked
```

This confirmed that the original baseline configuration was preserved.

---

# Final Terraform Validation

Final commands:

```powershell
terraform fmt -check
terraform validate
terraform plan
```

Expected final result:

```text
No changes. Your infrastructure matches the configuration.
```

The final environment contains no unintended Terraform drift.

---

# Final Architecture

The OCI application path now follows:

```text
                    Internet
                       |
                       v
               +---------------+
               |    OCI WAF    |
               +---------------+
                       |
                       v
             +-------------------+
             | OCI Load Balancer |
             | Listener HTTP :80 |
             +-------------------+
                       |
                       v
               +---------------+
               | Backend Set   |
               | /health check |
               +---------------+
                       |
                       v
          +----------------------------+
          | Private OCI Compute        |
          | Application subnet         |
          | No public IP               |
          +----------------------------+
                       |
                       v
                  Traefik :80
                       |
                       v
                  bobhub-app
                       |
          +------------+------------+
          |            |            |
          v            v            v
          /         /health      /whoami
```

---

# Security Model

The design preserves the private Compute architecture.

Principles:

```text
Compute has no public IP
SSH uses OCI Bastion
Application ingress goes through Load Balancer
WAF evaluates public requests
Load Balancer forwards approved traffic
Private backend receives application traffic
```

The application itself is not directly exposed to the Internet.

---

# FinOps

The implementation followed the BobHub FinOps strategy:

```text
Target out-of-pocket cost:
US$ 0

Free / credits:
preferred

Persistent paid resources:
avoid when practical

Learning resources:
destroy when no longer required
```

The Load Balancer was intentionally configured using the minimum learning capacity:

```text
10 Mbps minimum
10 Mbps maximum
```

Logging was kept disabled during the initial lab to avoid unnecessary additional consumption.

Current OCI pricing and Free Tier eligibility should always be checked before keeping the Load Balancer or WAF running for extended periods.

---

# Key Lessons

## Load Balancer

The OCI Load Balancer acts as the application traffic distributor.

```text
Load Balancer
→ WHERE the request goes
```

Important components:

```text
Public frontend
Listener
Backend Set
Backend
Health Check
```

---

## WAF

OCI WAF evaluates application requests before allowing them to continue.

```text
WAF
→ WHETHER the request may pass
```

Important components:

```text
WAF Policy
Firewall
Enforcement Point
Actions
Access Rules
JMESPath Conditions
```

---

## Health Checks

A useful health check should validate the application path instead of only testing whether a virtual machine is running.

The BobHub health check validates:

```text
Load Balancer
→ VM network
→ Docker
→ Traefik
→ Application
→ /health
```

---

## Terraform Import

Terraform can adopt resources that already exist.

The workflow used was:

```text
Create manually
→ understand behavior
→ validate
→ write Terraform
→ import
→ inspect state
→ adjust configuration
→ no drift
```

This is useful when introducing Terraform into existing infrastructure.

---

## Terraform State as Learning Evidence

`terraform state show` exposed OCI API defaults and provider representation that were not obvious from the Console.

Examples included:

```text
Request ID configuration
WAF pre-configured actions
WAF body representation
JMESPath rule structure
```

The imported state helped create Terraform configuration based on actual OCI behavior instead of assumptions.

---

## Terraform Lifecycle

The temporary WAF test demonstrated full lifecycle control:

```text
Terraform creates behavior
→ behavior validated

Terraform removes behavior
→ removal validated

Terraform plan
→ no drift
```

This provided stronger evidence than import alone.

---

# Acceptance Criteria Validation

The Issue #57 acceptance criteria were validated.

```text
[OK] OCI Load Balancer concepts understood through practical implementation

[OK] Public Load Balancer entry point functional

[OK] HTTP listener configured and validated

[OK] Backend Set configured and validated

[OK] Private OCI Compute registered as backend

[OK] Load Balancer health check uses /health

[OK] Backend health reached OK

[OK] Compute remains private

[OK] Compute has no public IP

[OK] Public application traffic reaches Traefik through the Load Balancer

[OK] / works through the public entry point

[OK] /health works through the public entry point

[OK] /whoami works through the public entry point

[OK] Normal browser/application access no longer requires SSH port forwarding

[OK] OCI WAF concepts understood through practical implementation

[OK] WAF Policy integrated with the application entry path

[OK] Normal traffic allowed

[OK] Safe blocking condition validated

[OK] Blocked traffic returns HTTP 403

[OK] Terraform manages the final Load Balancer infrastructure

[OK] Terraform manages the final WAF infrastructure

[OK] Existing manual infrastructure imported into Terraform

[OK] Terraform lifecycle validated with temporary WAF behavior

[OK] Temporary Terraform validation rule successfully removed

[OK] Permanent WAF rule remained functional

[OK] Final terraform plan reports no unintended changes
```

---

# Final State

The BobHub OCI environment now has a cloud-managed public application entry layer.

Previous state:

```text
Browser
   ↓
SSH forwarding
   ↓
OCI Bastion
   ↓
Private Compute
   ↓
Traefik
   ↓
BobHub App
```

Current state:

```text
Internet
   ↓
OCI WAF
   ↓
OCI Load Balancer
   ↓
Private Compute
   ↓
Traefik
   ↓
BobHub App
```

OCI Bastion remains dedicated to administrative SSH access.

Application traffic no longer depends on Bastion or SSH port forwarding.

---

# BobHub v0.3.0 Progress

Completed OCI foundation:

```text
VCN
Subnets
Internet Gateway
NAT Gateway
Route Tables
Security Lists
OCI Bastion
Private Compute
Ansible configuration
Docker
Traefik
BobHub application
OCI Load Balancer
OCI WAF
Terraform import
Terraform lifecycle validation
```

The OCI environment now provides a functional application platform that can later participate in the BobHub multi-cloud traffic distribution and disaster recovery architecture.

---

# Checkpoint Result

```text
Issue #57
Provision OCI Load Balancer and WAF application entry

Status:
Technically validated

Load Balancer:
OK

Backend health:
OK

Application:
OK

WAF allow behavior:
OK

WAF block behavior:
OK

Terraform import:
OK

Terraform lifecycle:
OK

Terraform drift:
None
```