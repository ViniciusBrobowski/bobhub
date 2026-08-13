variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint URL"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox VE API token used by Terraform"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Disable TLS certificate verification for lab environments"
  type        = bool
  default     = false
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "vm_cpu_cores" {
  description = "Number of CPU cores for the virtual machine"
  type        = number
  default     = 2
}

variable "vm_memory_mb" {
  description = "Memory assigned to the virtual machine in MB"
  type        = number
  default     = 2048
}

variable "vm_disk_size_gb" {
  description = "Disk size for the virtual machine in GB"
  type        = number
  default     = 20
}

variable "proxmox_node" {
  description = "Proxmox node where the VM will be created"
  type        = string
}

variable "proxmox_storage" {
  description = "Proxmox storage used for the virtual machine disk"
  type        = string
}

variable "proxmox_network_bridge" {
  description = "Proxmox network bridge for the virtual machine"
  type        = string
  default     = "vmbr0"
}