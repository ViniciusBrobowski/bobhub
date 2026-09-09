variable "location" {
  description = "Azure region used by the BobHub shared data layer."
  type        = string
  default     = "brazilsouth"
}

variable "environment" {
  description = "Environment classification."
  type        = string
  default     = "lab"
}

variable "postgresql_admin_password" {
  description = "Administrator password for Azure PostgreSQL Flexibe Server."
  type        = string
  sensitive   = true
}

variable "oci_nat_public_ip" {
  description = "Public egress IP of the OCI NAT Gateway allowed to acess Azure PostgreSQL."
  type        = string
}