resource "oci_waf_web_app_firewall_policy" "bobhub" {
  compartment_id = var.compartment_ocid
  display_name   = "bobhub-v03-oci-waf-policy"

  actions {
    name = "Pre-configured Check Action"
    type = "CHECK"
  }

  actions {
    name = "Pre-configured Allow Action"
    type = "ALLOW"
  }

  actions {
    name = "Pre-configured 401 Response Code Action"
    type = "RETURN_HTTP_RESPONSE"
    code = 401

    body {
      type = "STATIC_TEXT"

      text = jsonencode({
        code    = "401"
        message = "Unauthorized"
      })
    }

    headers {
      name  = "Content-Type"
      value = "application/json"
    }
  }

  actions {
    name = "bobhub-test-block"
    type = "RETURN_HTTP_RESPONSE"
    code = 403

    body {
      type     = "DYNAMIC"
      template = "BobHub WAF test blocked"
    }
  }

  request_access_control {
    default_action_name = "Pre-configured Allow Action"

    rules {
      name               = "bobhub-block-test-header"
      type               = "ACCESS_CONTROL"
      condition_language = "JMESPATH"

      condition = "http.request.headers.\"x-bobhub-waf-test\"[0] == 'block'"

      action_name = "bobhub-test-block"
    }
  }
}

resource "oci_waf_web_app_firewall" "bobhub" {
  compartment_id = var.compartment_ocid

  display_name = "bobhub-v03-oci-waf"

  backend_type = "LOAD_BALANCER"

  load_balancer_id           = oci_load_balancer_load_balancer.bobhub.id
  web_app_firewall_policy_id = oci_waf_web_app_firewall_policy.bobhub.id
}