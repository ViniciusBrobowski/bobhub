data "oci_identity_availability_domains" "available" {
  compartment_id = var.compartment_ocid
}