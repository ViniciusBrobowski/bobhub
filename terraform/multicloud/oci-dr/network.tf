resource "oci_core_vcn" "bobhub" {
  compartment_id = var.compartment_ocid

  cidr_blocks = [
    var.vcn_cidr
  ]

  display_name = "bobhub-v03-vcn"
  dns_label    = "bobhubv03"

  freeform_tags = {
    Project     = "BobHub"
    Version     = "v0.3.0"
    Environment = "lab"
    ManagedBy   = "Terraform"
    Purpose     = "oci-dr-network"
    CostClass   = "persistent"
  }
}

resource "oci_core_internet_gateway" "bobhub" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.bobhub.id

  display_name = "bobhub-v03-igw"
  enabled      = true

  freeform_tags = {
    Project     = "BobHub"
    Version     = "v0.3.0"
    Environment = "lab"
    ManagedBy   = "Terraform"
    Purpose     = "public-internet-access"
    CostClass   = "persistent"
  }
}

resource "oci_core_nat_gateway" "bobhub" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.bobhub.id

  display_name  = "bobhub-v03-nat"
  block_traffic = false

  freeform_tags = {
    Project     = "BobHub"
    Version     = "v0.3.0"
    Environment = "lab"
    ManagedBy   = "Terraform"
    Purpose     = "private-internet-egress"
    CostClass   = "temporary"
  }
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.bobhub.id

  display_name = "bobhub-v03-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.bobhub.id
  }

  freeform_tags = {
    Project     = "BobHub"
    Version     = "v0.3.0"
    Environment = "lab"
    ManagedBy   = "Terraform"
    Purpose     = "public-routing"
    CostClass   = "persistent"
  }
}

resource "oci_core_route_table" "application" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.bobhub.id

  display_name = "bobhub-v03-application-rt"

  freeform_tags = {
    Project     = "BobHub"
    Version     = "v0.3.0"
    Environment = "lab"
    ManagedBy   = "Terraform"
    Purpose     = "application-routing"
    CostClass   = "persistent"
  }

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.bobhub.id
  }
}

resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.bobhub.id

  display_name = "bobhub-v03-public-sl"

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  freeform_tags = {
    Project     = "BobHub"
    Version     = "v0.3.0"
    Environment = "lab"
    ManagedBy   = "Terraform"
    Purpose     = "public-security-baseline"
    CostClass   = "persistent"
  }
}

resource "oci_core_security_list" "application" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.bobhub.id

  display_name = "bobhub-v03-application-sl"

  ingress_security_rules {
    protocol = "6"
    source   = var.public_subnet_cidr

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.public_subnet_cidr

    tcp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  freeform_tags = {
    Project     = "BobHub"
    Version     = "v0.3.0"
    Environment = "lab"
    ManagedBy   = "Terraform"
    Purpose     = "application-security-baseline"
    CostClass   = "persistent"
  }
}

resource "oci_core_subnet" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.bobhub.id

  cidr_block   = var.public_subnet_cidr
  display_name = "bobhub-v03-public-subnet"
  dns_label    = "public"

  route_table_id    = oci_core_route_table.public.id
  security_list_ids = [oci_core_security_list.public.id]

  prohibit_public_ip_on_vnic = false

  freeform_tags = {
    Project     = "BobHub"
    Version     = "v0.3.0"
    Environment = "lab"
    ManagedBy   = "Terraform"
    Purpose     = "public-layer"
    CostClass   = "persistent"
  }
}

resource "oci_core_subnet" "application" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.bobhub.id

  cidr_block   = var.application_subnet_cidr
  display_name = "bobhub-v03-application-subnet"
  dns_label    = "app"

  route_table_id    = oci_core_route_table.application.id
  security_list_ids = [oci_core_security_list.application.id]

  prohibit_public_ip_on_vnic = true

  freeform_tags = {
    Project     = "BobHub"
    Version     = "v0.3.0"
    Environment = "lab"
    ManagedBy   = "Terraform"
    Purpose     = "application-layer"
    CostClass   = "persistent"
  }
}