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