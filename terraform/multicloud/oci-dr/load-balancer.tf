resource "oci_load_balancer_load_balancer" "bobhub" {
  compartment_id = var.compartment_ocid

  display_name = "bobhub-v03-oci-lb"

  shape      = "flexible"
  is_private = false

  is_request_id_enabled = true
  request_id_header     = "X-Request-Id"

  subnet_ids = [
    oci_core_subnet.public.id
  ]

  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 10
  }
}

resource "oci_load_balancer_backend_set" "application" {
  load_balancer_id = oci_load_balancer_load_balancer.bobhub.id

  name   = "bs_lb_2026-0830-1700"
  policy = "ROUND_ROBIN"

  health_checker {
    protocol = "HTTP"
    port     = 80
    url_path = "/health"

    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
    return_code       = 200
  }
}

resource "oci_load_balancer_backend" "application" {
  load_balancer_id = oci_load_balancer_load_balancer.bobhub.id
  backendset_name  = oci_load_balancer_backend_set.application.name

  ip_address = oci_core_instance.application.private_ip
  port       = 80

  backup  = false
  drain   = false
  offline = false
  weight  = 1
}

resource "oci_load_balancer_listener" "http" {
  load_balancer_id = oci_load_balancer_load_balancer.bobhub.id

  name                     = "bobhub-http-80"
  default_backend_set_name = oci_load_balancer_backend_set.application.name

  protocol = "HTTP"
  port     = 80
}