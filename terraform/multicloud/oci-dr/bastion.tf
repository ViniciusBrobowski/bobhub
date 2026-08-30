resource "oci_bastion_bastion" "bobhub" {
  bastion_type = "standard"

  compartment_id   = var.compartment_ocid
  target_subnet_id = oci_core_subnet.application.id

  name = "bobhub-v03-bastion"

  client_cidr_block_allow_list = [
    var.bastion_client_cidr
  ]

  max_session_ttl_in_seconds = 3600

  lifecycle {
    ignore_changes = [
      bastion_type
    ]
  }

  freeform_tags = {
    Project     = "BobHub"
    Version     = "v0.3.0"
    Environment = "lab"
    ManagedBy   = "Terraform"
    Purpose     = "private-administration"
    CostClass   = "persistent"
  }
}

resource "oci_core_network_security_group" "application" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.bobhub.id

  display_name = "bobhub-v03-application-nsg"

  freeform_tags = {
    Project     = "BobHub"
    Version     = "v0.3.0"
    Environment = "lab"
    ManagedBy   = "Terraform"
    Purpose     = "application-access"
    CostClass   = "persistent"
  }
}

resource "oci_core_network_security_group_security_rule" "bastion_ssh" {
  network_security_group_id = oci_core_network_security_group.application.id

  direction   = "INGRESS"
  protocol    = "6"
  source_type = "CIDR_BLOCK"
  source      = "${oci_bastion_bastion.bobhub.private_endpoint_ip_address}/32"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}