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
  description = "Disable TLS certificate verification for Plab environments"
  type        = bool
  default     = false
}