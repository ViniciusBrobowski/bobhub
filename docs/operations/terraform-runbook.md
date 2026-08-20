# BobHub Terraform Runbook

## Objective

This runbook documents how to operate, validate and troubleshoot Terraform in the BobHub Proxmox lab.

It is intended to be used as an operational guide for initializing Terraform, validating configuration, reviewing infrastructure changes, applying plans, inspecting state and safely managing infrastructure resources.

The current Terraform implementation manages virtual machines through the Proxmox VE API.

---

## Terraform Flow

The current BobHub Terraform flow is:

```text
Terraform configuration
        ↓
bpg/proxmox provider
        ↓
Proxmox VE API
        ↓
Proxmox node
        ↓
Virtual Machine
```

Terraform runs from the administration workstation and communicates with Proxmox using an API Token.

---

## File Locations

Main Terraform files:

```text
terraform/proxmox/main.tf
terraform/proxmox/provider.tf
terraform/proxmox/variables.tf
terraform/proxmox/terraform.tfvars.example
```

Local sensitive file:

```text
terraform/proxmox/terraform.tfvars
```

Terraform local state and generated plan files may also exist in the working directory.

Examples:

```text
terraform.tfstate
terraform.tfstate.backup
*.tfplan
.terraform/
.terraform.lock.hcl
```

Files containing secrets or local execution artifacts must not be committed unless intentionally versioned.

---

## Provider

The BobHub Proxmox lab uses the following Terraform provider:

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }
  }
}
```

Provider configuration:

```hcl
provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}
```

The provider communicates directly with the Proxmox VE API.

---

## Terraform Variables

The local Terraform environment uses variables for both Proxmox access and VM configuration.

Example:

```hcl
proxmox_endpoint  = "https://PROXMOX-IP:8006/"
proxmox_api_token = "terraform@pve!provider=SECRET"
proxmox_insecure  = true

vm_name         = "lab-vm-01"
vm_cpu_cores    = 2
vm_memory_mb    = 2048
vm_disk_size_gb = 20

proxmox_node           = "pve"
proxmox_storage        = "local-lvm"
proxmox_network_bridge = "vmbr0"
```

Real secrets must only exist in:

```text
terraform.tfvars
```

The repository should contain only an example file:

```text
terraform.tfvars.example
```

---

## API Authentication

Terraform authenticates to Proxmox using an API Token.

Example format:

```text
terraform@pve!provider=SECRET
```

The real token must never be:

* committed to Git
* added to documentation
* included in screenshots
* copied into issues or pull requests
* stored directly inside `provider.tf`

If a token is exposed, rotate it immediately.

---

## Proxmox Permissions

Terraform should use a dedicated Proxmox user and role following least privilege principles.

Current lab user:

```text
terraform@pve
```

Current lab role:

```text
Terraform
```

Permissions validated in the lab include:

```text
Datastore.AllocateSpace
Datastore.Audit
SDN.Use
Sys.Audit
VM.Allocate
VM.Audit
VM.Config.CDROM
VM.Config.CPU
VM.Config.Disk
VM.Config.HWType
VM.Config.Memory
VM.Config.Network
VM.Config.Options
VM.PowerMgmt
```

The role is applied at:

```text
/
```

with propagation enabled.

Do not use the Proxmox root account for Terraform automation.

---

## Initialize Terraform

Change to the Terraform directory:

```powershell
cd terraform\proxmox
```

Initialize Terraform:

```powershell
terraform init
```

This operation:

```text
Reads provider requirements
        ↓
Downloads required providers
        ↓
Creates or updates .terraform/
        ↓
Creates or updates .terraform.lock.hcl
```

Expected result:

```text
Terraform has been successfully initialized!
```

Run `terraform init` when:

* cloning the repository for the first time
* adding or changing providers
* changing provider versions
* Terraform reports that initialization is required

---

## Format Terraform Files

Format Terraform configuration:

```powershell
terraform fmt
```

To check formatting without modifying files:

```powershell
terraform fmt -check
```

Run formatting before validation and before committing Terraform changes.

---

## Validate Terraform Configuration

Validate configuration:

```powershell
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

Validation checks Terraform syntax and internal configuration consistency.

It does not guarantee that Proxmox permissions, storage, networks or other external resources are available.

---

## Generate a Terraform Plan

Generate a plan:

```powershell
terraform plan -var-file="terraform.tfvars"
```

Terraform compares:

```text
Configuration
     +
Terraform State
     +
Current Infrastructure
     ↓
Execution Plan
```

Review the plan carefully before applying it.

Terraform action symbols include:

```text
+   create

~   update in place

-   destroy

-/+ replace resource
```

Never apply infrastructure changes without reviewing the execution plan first.

---

## Save a Terraform Plan

For controlled execution, save the plan:

```powershell
terraform plan -var-file="terraform.tfvars" -out="lab-vm.tfplan"
```

Apply exactly that plan:

```powershell
terraform apply "lab-vm.tfplan"
```

This ensures Terraform applies the same actions that were previously reviewed.

Generated `.tfplan` files are local execution artifacts and should not be committed.

---

## Apply Terraform Changes

Apply a previously saved plan:

```powershell
terraform apply "lab-vm.tfplan"
```

Or apply directly:

```powershell
terraform apply -var-file="terraform.tfvars"
```

Using a saved plan is preferred when validating infrastructure changes manually.

Successful provisioning of the first BobHub VM validated the following flow:

```text
Terraform
↓
bpg/proxmox
↓
Proxmox API Token
↓
Terraform role
↓
Proxmox node
↓
Storage
↓
Network bridge
↓
VM created
```

---

## Current VM Resource

The first BobHub VM provisioned by Terraform uses the resource:

```hcl
resource "proxmox_virtual_environment_vm" "ubuntu_vm"
```

The resource manages:

```text
VM name
CPU
Memory
Disk
Network bridge
ISO attachment
Boot order
Tags
Power state configuration
```

Example boot configuration:

```hcl
boot_order = ["scsi0", "ide2"]
```

This means:

```text
scsi0
  ↓
Primary boot device

ide2
  ↓
Secondary boot device / installation ISO
```

---

## Inspect Terraform State

List resources currently tracked by Terraform:

```powershell
terraform state list
```

Example:

```text
proxmox_virtual_environment_vm.ubuntu_vm
```

Inspect a specific resource:

```powershell
terraform state show proxmox_virtual_environment_vm.ubuntu_vm
```

Terraform State represents Terraform's understanding of managed infrastructure.

It should not be manually edited unless absolutely necessary and the impact is fully understood.

---

## Terraform State Strategy

Terraform State is critical because it maps Terraform resources to real infrastructure.

Conceptually:

```text
main.tf
   ↓
Terraform
   ↔
terraform.tfstate
   ↔
Proxmox
```

The state contains infrastructure metadata and may contain sensitive information.

Local state files must not be committed to a public repository.

Before modifying or deleting state manually, create a backup.

---

## Refresh and Infrastructure State

Terraform normally refreshes resource information before planning.

Standard command:

```powershell
terraform plan -var-file="terraform.tfvars"
```

During the lab, there was a case where the current Terraform configuration and the stored state needed to be compared without refreshing infrastructure information.

The following command was used:

```powershell
terraform plan -refresh=false -var-file="terraform.tfvars"
```

This allowed Terraform to compare configuration against the existing state without querying and updating the state from the current Proxmox configuration first.

Use `-refresh=false` only when you understand why refresh behavior must be bypassed.

It should not be the default Terraform workflow.

---

## Configuration Drift

Configuration drift occurs when infrastructure is changed outside Terraform.

Example from the BobHub nested Proxmox lab:

```bash
qm set 100 --kvm 0
```

This configuration was changed directly in Proxmox and was not originally represented in Terraform.

Conceptually:

```text
Terraform configuration
        ↓
Expected infrastructure

Manual Proxmox change
        ↓
Actual infrastructure changes

Expected != Actual
        ↓
Drift
```

Manual infrastructure changes should be avoided when Terraform is intended to be the source of truth.

If a manual change is required for troubleshooting:

1. Document the change.
2. Determine whether it belongs in Terraform.
3. Review the next Terraform plan carefully.
4. Either represent the change in Terraform or intentionally revert it.

---

## Terraform Destroy

Preview destruction before executing it:

```powershell
terraform plan -destroy -var-file="terraform.tfvars"
```

Destroy managed infrastructure:

```powershell
terraform destroy -var-file="terraform.tfvars"
```

Terraform will request confirmation before destroying resources unless automatic confirmation is explicitly enabled.

Do not run `terraform destroy` without reviewing which resources will be removed.

In the BobHub lab, virtual machines may contain manually installed systems or troubleshooting work that will be permanently lost after destruction.

---

## Validate Before Commit

Before committing Terraform changes:

```powershell
terraform fmt
terraform validate
terraform plan -var-file="terraform.tfvars"
```

Then verify:

```powershell
git status
```

Sensitive files must not appear in staged changes.

Important examples:

```text
terraform.tfvars
terraform.tfstate
terraform.tfstate.backup
*.tfplan
```

---

## Common Issues and Fixes

### Invalid Terraform Resource Type

An early VM resource definition used an incorrect resource name.

Incorrect:

```hcl
resource "proxmox_virtual_environment" "ubuntu_vm" {
```

Correct:

```hcl
resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
```

Always confirm the exact resource type supported by the installed provider version.

---

### Invalid Network Block

An incorrect network block was initially used.

Incorrect:

```hcl
network {
```

Correct:

```hcl
network_device {
```

Provider schemas are strict.

When Terraform reports an unsupported block or argument, validate the configuration against the provider resource schema.

---

### Missing Variables

Terraform planning may fail if variables required by `variables.tf` are missing from the provided `.tfvars` file.

Check:

```text
variables.tf
```

against:

```text
terraform.tfvars
```

Then retry:

```powershell
terraform validate
terraform plan -var-file="terraform.tfvars"
```

---

### Authentication Failure

If Terraform cannot authenticate to Proxmox, validate:

* Proxmox endpoint
* API Token format
* token secret
* token status
* user status
* assigned role
* permission propagation

Do not print or share the real API Token while troubleshooting.

---

### Permission Denied

If Terraform authenticates but cannot create or modify resources, check the Terraform role.

Common areas include:

```text
VM allocation
VM configuration
Storage allocation
Network access
Power management
```

Avoid solving permission problems by assigning administrator access immediately.

Add only the permissions Terraform actually requires.

---

### Terraform Does Not Detect Expected Change

First validate:

```powershell
terraform state show proxmox_virtual_environment_vm.ubuntu_vm
```

Then compare the state with the current HCL configuration.

If required during troubleshooting:

```powershell
terraform plan -refresh=false -var-file="terraform.tfvars"
```

Do not use `-refresh=false` automatically.

The difference may be caused by:

* provider refresh behavior
* state values
* manual infrastructure changes
* provider normalization
* remote API behavior

---

### Boot Order Change

The first BobHub VM required temporary changes to boot order during operating system troubleshooting.

Installation or recovery:

```hcl
boot_order = ["ide2", "scsi0"]
```

Normal disk boot:

```hcl
boot_order = ["scsi0", "ide2"]
```

Terraform successfully detected and applied the boot order change.

This demonstrated an in-place infrastructure update:

```text
Plan: 0 to add, 1 to change, 0 to destroy
```

---

## Nested Proxmox Lab Limitation

The current BobHub Proxmox lab uses the following architecture:

```text
Windows 11
    ↓
VirtualBox
    ↓
Proxmox VE
    ↓
QEMU VM
```

Although nested virtualization was enabled in VirtualBox, the Proxmox guest did not receive:

```text
/dev/kvm
```

Starting the Terraform-created VM with KVM enabled resulted in:

```text
KVM virtualisation configured, but not available
```

For this laboratory only, the VM was configured manually with:

```bash
qm set 100 --kvm 0
```

This forces QEMU software emulation.

This workaround is specific to the nested lab and should not be considered a recommended Proxmox production configuration.

A bare-metal Proxmox installation should use hardware virtualization and KVM.

---

## Guest Operating System Limitation

Terraform successfully provisioned the VM and configured its infrastructure resources.

Guest operating system boot troubleshooting was intentionally stopped after Terraform provisioning had already been validated.

The nested architecture introduced guest boot problems unrelated to the Terraform provisioning objective.

The validated boundary is therefore:

```text
Terraform configuration
        ↓
Proxmox API
        ↓
VM resource created
        ↓
Infrastructure provisioning validated
```

Guest OS installation and boot behavior are separate from Terraform resource provisioning.

A future bare-metal Proxmox environment can be used to validate the complete guest operating system lifecycle.

---

## Future Improvement: Cloud-Init

The current lab uses an Ubuntu installation ISO.

A more automation-oriented future implementation should use:

```text
Terraform
↓
Proxmox
↓
Ubuntu Cloud Image
↓
Cloud-Init
↓
SSH configuration
↓
Automatically provisioned VM
```

This eliminates the need for manual operating system installation.

Future Terraform improvements may include:

* Ubuntu Cloud Images
* Cloud-Init
* SSH public keys
* automatic network configuration
* VM templates
* reusable Terraform modules
* remote Terraform State
* CI validation

---

## Security Notes

Do not commit:

```text
terraform.tfvars
terraform.tfstate
terraform.tfstate.backup
*.tfplan
```

Do not expose:

* Proxmox API Tokens
* passwords
* private keys
* infrastructure credentials
* internal infrastructure details unnecessarily

Use:

```text
terraform.tfvars.example
```

to document expected variables without including real secrets.

Terraform should authenticate through a dedicated account following least privilege principles.

---

## Recovery Procedure

If Terraform operations fail:

1. Confirm the working directory:

```powershell
cd terraform\proxmox
```

2. Initialize Terraform:

```powershell
terraform init
```

3. Format configuration:

```powershell
terraform fmt
```

4. Validate configuration:

```powershell
terraform validate
```

5. Review variables:

```text
variables.tf
terraform.tfvars
```

6. Generate a plan:

```powershell
terraform plan -var-file="terraform.tfvars"
```

7. Inspect Terraform State if necessary:

```powershell
terraform state list
terraform state show proxmox_virtual_environment_vm.ubuntu_vm
```

8. Check Proxmox configuration directly when required:

```bash
qm config 100
```

9. Compare:

```text
Terraform configuration
Terraform state
Proxmox actual configuration
```

10. Only use:

```powershell
terraform plan -refresh=false -var-file="terraform.tfvars"
```

when troubleshooting specifically requires comparison without refreshing remote state.

---

## Operational Checklist

Use this checklist after Terraform changes:

* [ ] Working on the correct Git branch
* [ ] `terraform.tfvars` exists locally
* [ ] Secrets are not present in tracked files
* [ ] `terraform init` completed successfully
* [ ] `terraform fmt` completed successfully
* [ ] `terraform validate` completed successfully
* [ ] Terraform plan was reviewed
* [ ] Unexpected destroy or replacement actions are absent
* [ ] Terraform apply completed successfully
* [ ] Proxmox resource reflects the expected configuration
* [ ] Terraform State reflects the managed resource
* [ ] Manual infrastructure changes are documented
* [ ] `.tfplan` files are not staged
* [ ] `terraform.tfvars` is not staged
* [ ] Terraform State files are not staged
* [ ] Documentation was updated when behavior changed

---

## Basic Terraform Workflow

The standard BobHub Terraform workflow is:

```text
Edit Terraform configuration
        ↓
terraform fmt
        ↓
terraform validate
        ↓
terraform plan
        ↓
Review changes
        ↓
terraform apply
        ↓
Validate Proxmox
        ↓
Review git status
        ↓
Commit
        ↓
Pull Request
```

When using saved plans:

```text
terraform plan -out=<plan>
        ↓
Review plan
        ↓
terraform apply <plan>
```

---

## Related Documentation

```text
docs/architecture/promox-lab.md

docs/planning/bobhub-v0.2-terraform-proxmox.md

docs/planning/devops-drd-roadmap.md

docs/planning/roadmap.md
```

---

## Related Terraform Files

```text
terraform/proxmox/main.tf

terraform/proxmox/provider.tf

terraform/proxmox/variables.tf

terraform/proxmox/terraform.tfvars.example
```

---

## Version Goal

This runbook is part of the BobHub Terraform and Infrastructure as Code evolution.

It documents the minimum operational knowledge required to safely initialize, validate, plan, apply, inspect and troubleshoot Terraform resources in the current Proxmox lab.

The first real BobHub VM provisioned through Terraform validated the core Infrastructure as Code workflow and established the foundation for future automated infrastructure provisioning.
