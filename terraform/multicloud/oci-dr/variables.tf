variable "compartment_ocid" {
  description = "OCID of the BobHub OCI compartment"
  type        = string
}

variable "vcn_cidr" {
  description = "CIDR block for the BobHub OCI VCN"
  type        = string
  default     = "10.40.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.40.10.0/24"
}

variable "application_subnet_cidr" {
  description = "CIDR block for the application subnet"
  type        = string
  default     = "10.40.20.0/24"
}
variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for OCI compute access"
  type        = string
}

variable "compute_shape" {
  description = "OCI shape used by the BobHub application instance"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "compute_ocpus" {
  description = "Number of OCPUs assigned to the BobHub application instance"
  type        = number
  default     = 1
}

variable "compute_memory_gbs" {
  description = "Memory in GB assigned to the BobHub application instance"
  type        = number
  default     = 6
}

variable "bastion_client_cidr" {
  description = "Public CIDR allowed to connect to the OCI Bastion"
  type        = string
}