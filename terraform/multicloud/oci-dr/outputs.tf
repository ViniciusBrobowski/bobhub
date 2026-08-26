output "availability_domains" {
  description = "Availability Domains available to the BobHub compartment"

  value = [
    for ad in data.oci_identity_availability_domains.available.availability_domains :
    ad.name
  ]
}

output "vcn_id" {
  description = "OCID of the BobHub OCI VCN"
  value       = oci_core_vcn.bobhub.id
}

output "vcn_cidr" {
  description = "CIDR block of the BobHub OCI VCN"
  value       = oci_core_vcn.bobhub.cidr_blocks
}

output "public_subnet_id" {
  description = "OCID of the BobHub public subnet"
  value       = oci_core_subnet.public.id
}

output "application_subnet_id" {
  description = "OCID of the BobHub application subnet"
  value       = oci_core_subnet.application.id
}

output "internet_gateway_id" {
  description = "OCID of the BobHub Internet Gateway"
  value       = oci_core_internet_gateway.bobhub.id
}