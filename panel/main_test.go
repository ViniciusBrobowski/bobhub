package main

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestTruncate(t *testing.T) {
	tests := []struct {
		name  string
		value string
		max   int
		want  string
	}{
		{name: "short", value: "bobhub", max: 10, want: "bobhub"},
		{name: "exact", value: "bobhub", max: 6, want: "bobhub"},
		{name: "long", value: "bobhub-lab", max: 6, want: "bobhub..."},
		{name: "unicode", value: "operação", max: 4, want: "oper..."},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := truncate(test.value, test.max); got != test.want {
				t.Fatalf("truncate(%q, %d) = %q, want %q", test.value, test.max, got, test.want)
			}
		})
	}
}

func TestMapString(t *testing.T) {
	values := map[string]any{
		"ip":    "203.0.113.10",
		"count": 2,
	}

	if got := mapString(values, "ip"); got != "203.0.113.10" {
		t.Fatalf("mapString(ip) = %q", got)
	}

	if got := mapString(values, "count"); got != "" {
		t.Fatalf("mapString(count) = %q, want empty string", got)
	}

	if got := mapString(nil, "ip"); got != "" {
		t.Fatalf("mapString(nil) = %q, want empty string", got)
	}
}

func TestNewToken(t *testing.T) {
	token := newToken()

	if len(token) != 64 {
		t.Fatalf("newToken() length = %d, want 64 hex characters", len(token))
	}

	if token == newToken() {
		t.Fatal("newToken() returned the same token twice")
	}
}

func TestParseLBIP(t *testing.T) {
	tests := []struct {
		name  string
		state string
		want  string
	}{
		{
			name: "ip_address_details",
			state: `
resource "oci_load_balancer_load_balancer" "bobhub" {
    ip_address_details = [
        {
            ip_address = "203.0.113.10"
            is_public  = true
        },
    ]
}
`,
			want: "203.0.113.10",
		},
		{
			name:  "legacy ip_addresses",
			state: "ip_addresses = [\n    \"203.0.113.11\",\n]",
			want:  "203.0.113.11",
		},
		{
			name:  "empty list",
			state: "ip_addresses = []",
			want:  "",
		},
		{
			name:  "no addresses",
			state: "",
			want:  "",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := parseLBIP(test.state); got != test.want {
				t.Fatalf("parseLBIP() = %q, want %q", got, test.want)
			}
		})
	}
}

func TestApplyEnvironmentFillsMissingFields(t *testing.T) {
	t.Setenv("BOBHUB_DB_ADMIN_USER", "vault-admin")
	t.Setenv("TF_VAR_postgresql_admin_password", "vault-admin-secret")
	t.Setenv("BOBHUB_DB_PASSWORD", "vault-app-secret")
	t.Setenv("TF_VAR_oci_nat_public_ip", "203.0.113.50")

	req := RunRequest{}
	req.applyEnvironment()

	if req.AdminUser != "vault-admin" {
		t.Fatalf("AdminUser = %q, want environment value", req.AdminUser)
	}

	if req.AdminPassword != "vault-admin-secret" {
		t.Fatalf("AdminPassword = %q, want environment value", req.AdminPassword)
	}

	if req.AppPassword != "vault-app-secret" {
		t.Fatalf("AppPassword = %q, want environment value", req.AppPassword)
	}

	if req.NATIP != "203.0.113.50" {
		t.Fatalf("NATIP = %q, want environment value", req.NATIP)
	}
}

func TestApplyEnvironmentKeepsExplicitValues(t *testing.T) {
	t.Setenv("BOBHUB_DB_ADMIN_USER", "vault-admin")
	t.Setenv("TF_VAR_postgresql_admin_password", "vault-admin-secret")
	t.Setenv("BOBHUB_DB_PASSWORD", "vault-app-secret")
	t.Setenv("TF_VAR_oci_nat_public_ip", "203.0.113.50")

	req := RunRequest{
		AdminUser:     "form-admin",
		AdminPassword: "form-admin-secret",
		AppPassword:   "form-app-secret",
		NATIP:         "198.51.100.10",
	}

	req.applyEnvironment()

	if req.AdminUser != "form-admin" || req.AdminPassword != "form-admin-secret" ||
		req.AppPassword != "form-app-secret" || req.NATIP != "198.51.100.10" {
		t.Fatalf("applyEnvironment overwrote explicit values: %+v", req)
	}
}

func TestSecretsStatusDoesNotExposeValues(t *testing.T) {
	t.Setenv("BOBHUB_DB_ADMIN_USER", "vault-admin")
	t.Setenv("TF_VAR_postgresql_admin_password", "super-secret")
	t.Setenv("BOBHUB_DB_PASSWORD", "app-secret")
	t.Setenv("TF_VAR_oci_nat_public_ip", "")

	status := secretsStatus()

	if !status.AdminUser || !status.AdminPassword || !status.AppPassword || status.NATIP {
		t.Fatalf("unexpected secrets status: %+v", status)
	}

	payload, err := json.Marshal(status)
	if err != nil {
		t.Fatalf("marshal secrets status: %v", err)
	}

	for _, secret := range []string{"vault-admin", "super-secret", "app-secret"} {
		if strings.Contains(string(payload), secret) {
			t.Fatalf("serialized secrets status leaked %q: %s", secret, payload)
		}
	}
}
