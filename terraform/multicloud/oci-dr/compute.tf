data "oci_core_images" "ubuntu" {
  compartment_id = var.compartment_ocid

  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = var.compute_shape
  state                    = "AVAILABLE"

  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

resource "oci_core_instance" "application" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.available.availability_domains[0].name

  display_name = "bobhub-v03-app-01"
  shape        = var.compute_shape

  shape_config {
    ocpus         = var.compute_ocpus
    memory_in_gbs = var.compute_memory_gbs
  }

  create_vnic_details {
    subnet_id = oci_core_subnet.application.id

    assign_public_ip = false
    display_name     = "bobhub-v03-app-01-vnic"
    hostname_label   = "app01"

    nsg_ids = [
      oci_core_network_security_group.application.id
    ]
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }

  freeform_tags = {
    Project     = "BobHub"
    Version     = "v0.3.0"
    Environment = "lab"
    ManagedBy   = "Terraform"
    Purpose     = "oci-dr-application"
    CostClass   = "persistent"
  }
}