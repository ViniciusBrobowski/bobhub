#!/usr/bin/env bash
#
# BobHub v0.3 teardown — Linux edition.
#
# Equivalent to stop-v03-lab.ps1:
#   - stops the local SSH tunnel
#   - destroys the Azure data layer
#   - destroys the OCI infrastructure
#
# Terraform destroy is idempotent: when a state is already empty the script
# simply skips that layer.

set -Eeuo pipefail

NONINTERACTIVE=0

usage() {
  cat <<'EOF'
Uso: stop-v03-lab.sh [--non-interactive]

Variáveis de ambiente reconhecidas:
  TF_VAR_postgresql_admin_password     senha admin do PostgreSQL
  TF_VAR_oci_nat_public_ip             IP público do NAT (opcional)

Com --non-interactive, a senha precisa vir do ambiente e o Terraform recebe
-auto-approve.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --non-interactive|-n) NONINTERACTIVE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Argumento desconhecido: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "${BOBHUB_NONINTERACTIVE:-0}" == "1" ]]; then
  NONINTERACTIVE=1
fi

TF_AUTO_APPROVE=()
if (( NONINTERACTIVE )); then
  TF_AUTO_APPROVE=(-auto-approve)
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
OCI_DIR="$REPO_ROOT/terraform/multicloud/oci-dr"
AZURE_DIR="$REPO_ROOT/terraform/multicloud/azure-data"
RUN_DIR="$REPO_ROOT/.run"
TUNNEL_PID_FILE="$RUN_DIR/ssh-tunnel.pid"

POSTGRES_PASSWORD=""

die() {
  echo "ERRO: $*" >&2
  exit 1
}

step() {
  printf '\n==> %s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "comando '$1' não encontrado no PATH."
}

require_secret() {
  local label="$1" var="$2" value="${!2:-}"

  if [[ -n "$value" ]]; then
    printf '%s' "$value"
    return 0
  fi

  if (( NONINTERACTIVE )); then
    echo "ERRO: $label não informado. Defina $var." >&2
    return 1
  fi

  read -r -s -p "$label: " value
  echo >&2

  if [[ -z "$value" ]]; then
    echo "ERRO: $label não pode ser vazio." >&2
    return 1
  fi

  printf '%s' "$value"
}

trim() {
  printf '%s' "$1" | tr -d '[:space:]'
}

run_tf() {
  local dir="$1"
  shift
  if ! terraform -chdir="$dir" "$@"; then
    die "terraform $* falhou em $dir"
  fi
}

tf_output() {
  local dir="$1" name="$2"
  terraform -chdir="$dir" output -raw "$name" 2>/dev/null || true
}

ensure_azure_login() {
  if az account show --output json >/dev/null 2>&1; then
    return 0
  fi

  local helper="$SCRIPT_DIR/azure-login.sh"

  if [[ -x "$helper" ]]; then
    echo "Sessão Azure expirada; autenticando com o service principal..." >&2
    "$helper" || true
  fi

  az account show --output json >/dev/null 2>&1
}

state_has_resources() {
  terraform -chdir="$1" state list 2>/dev/null | grep -q .
}

cleanup() {
  unset TF_VAR_postgresql_admin_password TF_VAR_oci_nat_public_ip ARM_SUBSCRIPTION_ID 2>/dev/null || true
  POSTGRES_PASSWORD=""
}

trap cleanup EXIT

mkdir -p "$RUN_DIR"
chmod 700 "$RUN_DIR"

stop_tunnel() {
  local pid="" comm=""

  if [[ -f "$TUNNEL_PID_FILE" ]]; then
    pid="$(cat "$TUNNEL_PID_FILE" 2>/dev/null || true)"
  fi

  if [[ ! "$pid" =~ ^[0-9]+$ ]] || ! kill -0 "$pid" 2>/dev/null; then
    pid=""

    # Fallback: find the listener on port 2222 (same user only).
    local line
    line="$(ss -ltnp 2>/dev/null | awk 'NR > 1 && $4 ~ /:2222$/ {print; exit}' || true)"
    pid="$(sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p' <<<"$line" | head -n 1 || true)"
  fi

  if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
    comm="$(ps -p "$pid" -o comm= 2>/dev/null | tr -d '[:space:]' || true)"

    if [[ "$comm" == "ssh" ]]; then
      echo "Encerrando túnel SSH (PID $pid)..."
      kill "$pid" 2>/dev/null || true

      for _ in {1..10}; do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.5
      done

      kill -9 "$pid" 2>/dev/null || true
    else
      echo "A porta 2222 está com o processo '$comm' (PID $pid); não vou encerrá-lo."
    fi
  else
    echo "Nenhum túnel SSH ativo encontrado."
  fi

  rm -f "$TUNNEL_PID_FILE"

  if ss -ltn 2>/dev/null | awk 'NR > 1 {print $4}' | grep -q ':2222$'; then
    echo "Aviso: a porta 2222 continua em uso."
  fi
}

step "Validando ferramentas obrigatórias"
require_cmd terraform
require_cmd az
require_cmd jq
require_cmd ss

HAS_OCI=0
HAS_AZURE=0

if state_has_resources "$OCI_DIR"; then
  HAS_OCI=1
fi

if state_has_resources "$AZURE_DIR"; then
  HAS_AZURE=1
fi

step "Encerrando túnel SSH local"
stop_tunnel

if (( ! HAS_OCI && ! HAS_AZURE )); then
  step "Nada para destruir"
  echo "Os states do OCI e do Azure já estão vazios."
  echo "BobHub v0.3 shutdown concluído (no-op)."
  exit 0
fi

if (( HAS_AZURE )); then
  step "Validando autenticação do Azure"

  ensure_azure_login || true
  AZ_JSON="$(az account show --output json 2>/dev/null || true)"

  if [[ -z "$AZ_JSON" ]]; then
    die "Azure CLI não autenticado. Verifique o service principal em $HOME/.config/bobhub/azure-sp.json."
  fi

  AZ_SUB_ID="$(jq -r '.id // empty' <<<"$AZ_JSON")"
  AZ_SUB_NAME="$(jq -r '.name // empty' <<<"$AZ_JSON")"

  [[ -n "$AZ_SUB_ID" ]] || die "Não foi possível obter o ID da assinatura Azure."
  export ARM_SUBSCRIPTION_ID="$AZ_SUB_ID"

  echo "Azure subscription:"
  echo "  Nome: $AZ_SUB_NAME"
  echo "  ID:   $AZ_SUB_ID"
fi

step "Obtendo IP público do NAT Gateway (OCI)"

OCI_NAT_PUBLIC_IP="$(trim "${TF_VAR_oci_nat_public_ip:-}")"

if [[ -z "$OCI_NAT_PUBLIC_IP" ]]; then
  OCI_NAT_PUBLIC_IP="$(trim "$(tf_output "$OCI_DIR" nat_gateway_public_ip)")"
fi

if [[ -z "$OCI_NAT_PUBLIC_IP" ]]; then
  if (( HAS_OCI )); then
    die "Não foi possível determinar o IP público do NAT Gateway (defina TF_VAR_oci_nat_public_ip)."
  fi

  # Azure destroy does not use this value, but the variable is required by the
  # configuration. A placeholder is safe while the OCI state is empty.
  OCI_NAT_PUBLIC_IP="127.0.0.1"
fi

export TF_VAR_oci_nat_public_ip="$OCI_NAT_PUBLIC_IP"
echo "OCI NAT public IP: $OCI_NAT_PUBLIC_IP"

if (( HAS_AZURE )); then
  step "Carregando senha admin do PostgreSQL"

  POSTGRES_PASSWORD="$(require_secret "PostgreSQL admin password" TF_VAR_postgresql_admin_password)" || exit 1
  export TF_VAR_postgresql_admin_password="$POSTGRES_PASSWORD"

  step "Destruindo camada de dados Azure"
  run_tf "$AZURE_DIR" destroy "${TF_AUTO_APPROVE[@]}"
else
  echo "State do Azure já está vazio; pulando."
fi

if (( HAS_OCI )); then
  step "Destruindo infraestrutura OCI"
  run_tf "$OCI_DIR" destroy "${TF_AUTO_APPROVE[@]}"
else
  echo "State do OCI já está vazio; pulando."
fi

step "BobHub v0.3 shutdown concluído"

echo ""
echo "Azure data layer: destruído ou já vazio."
echo "OCI infrastructure: destruída ou já vazia."
echo "Túnel SSH local: encerrado."
