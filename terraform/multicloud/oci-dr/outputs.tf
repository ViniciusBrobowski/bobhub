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

output "application_instance_id" {
  description = "OCID of the BobHub OCI application instance"
  value       = oci_core_instance.application.id
}

output "application_instance_private_ip" {
  description = "Private IP address of the BobHub OCI application instance"
  value       = oci_core_instance.application.private_ip
}

output "application_instance_state" {
  description = "Current state of the BobHub OCI application instance"
  value       = oci_core_instance.application.state
}

output "application_image_name" {
  description = "Ubuntu image selected for the BobHub OCI application instance"
  value       = data.oci_core_images.ubuntu.images[0].display_name
}

output "bastion_id" {
  description = "OCID of the BobHub OCI Bastion"
  value       = oci_bastion_bastion.bobhub.id
}

output "bastion_private_endpoint_ip" {
  description = "Private endpoint IP of the BobHub OCI Bastion"
  value       = oci_bastion_bastion.bobhub.private_endpoint_ip_address
}

output "nat_gateway_id" {
  description = "OCID of the BobHub OCI NAT Gateway"
  value       = oci_core_nat_gateway.bobhub.id
}