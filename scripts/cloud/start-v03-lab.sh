#!/usr/bin/env bash
#
# BobHub v0.3 lifecycle — Linux edition.
#
# Equivalent to start-v03-lab.ps1, without PowerShell/WSL:
#   - Terraform (OCI + Azure)
#   - Azure CLI
#   - OCI CLI (Bastion session)
#   - OpenSSH tunnel (127.0.0.1:2222)
#   - Ansible (OCI application)
#
# Credentials are read from the environment when present; otherwise they are
# prompted for. Nothing is written to disk by this script.

set -Eeuo pipefail

NONINTERACTIVE=0

usage() {
  cat <<'EOF'
Uso: start-v03-lab.sh [--non-interactive]

Variáveis de ambiente reconhecidas:
  BOBHUB_DB_ADMIN_USER                 usuário admin do PostgreSQL
  TF_VAR_postgresql_admin_password     senha admin do PostgreSQL
  BOBHUB_DB_PASSWORD                   senha do usuário bobhub_app
  TF_VAR_oci_nat_public_ip             IP público do NAT (opcional)
  OCI_CONFIG_FILE                      padrão: ~/.oci/config
  OCI_SSH_PRIVATE_KEY                  padrão: ~/.ssh/bobhub-oci
  OCI_SSH_PUBLIC_KEY                   padrão: ~/.ssh/bobhub-oci.pub

Com --non-interactive, todas as credenciais precisam vir do ambiente e o
Terraform recebe -auto-approve.
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
ANSIBLE_DIR="$REPO_ROOT/ansible"
INVENTORY_FILE="$ANSIBLE_DIR/inventory/oci.ini"
RUN_DIR="$REPO_ROOT/.run"
TUNNEL_PID_FILE="$RUN_DIR/ssh-tunnel.pid"
TUNNEL_LOG="$RUN_DIR/ssh-tunnel.log"

BASTION_HOST="host.bastion.sa-vinhedo-1.oci.oraclecloud.com"
BASTION_SESSION_NAME="bobhub-v03-port-forward"

POSTGRES_PASSWORD=""
APP_DB_PASSWORD=""

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

require_value() {
  local label="$1" var="$2" value="${!2:-}"

  if [[ -n "${value//[[:space:]]/}" ]]; then
    printf '%s' "$value"
    return 0
  fi

  if (( NONINTERACTIVE )); then
    echo "ERRO: $label não informado. Defina $var." >&2
    return 1
  fi

  read -r -p "$label: " value

  if [[ -z "${value//[[:space:]]/}" ]]; then
    echo "ERRO: $label não pode ser vazio." >&2
    return 1
  fi

  printf '%s' "$value"
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

cleanup() {
  unset TF_VAR_postgresql_admin_password TF_VAR_oci_nat_public_ip \
    BOBHUB_DB_HOST BOBHUB_DB_NAME BOBHUB_DB_USER BOBHUB_DB_PASSWORD \
    BOBHUB_DB_ADMIN_USER BOBHUB_DB_ADMIN_PASSWORD 2>/dev/null || true
  POSTGRES_PASSWORD=""
  APP_DB_PASSWORD=""
}

trap cleanup EXIT

mkdir -p "$RUN_DIR"
chmod 700 "$RUN_DIR"

step "Validando ferramentas obrigatórias"
require_cmd terraform
require_cmd az
require_cmd oci
require_cmd ssh
require_cmd ansible-playbook
require_cmd jq
require_cmd ss

echo "Terraform, Azure CLI, OCI CLI, SSH, Ansible, jq e ss encontrados."

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

step "Provisionando infraestrutura OCI"
run_tf "$OCI_DIR" init
run_tf "$OCI_DIR" validate
run_tf "$OCI_DIR" apply "${TF_AUTO_APPROVE[@]}"

step "Obtendo IP público do NAT Gateway (OCI)"
OCI_NAT_PUBLIC_IP="$(trim "$(tf_output "$OCI_DIR" nat_gateway_public_ip)")"
[[ -n "$OCI_NAT_PUBLIC_IP" ]] || die "Não foi possível obter nat_gateway_public_ip."
export TF_VAR_oci_nat_public_ip="$OCI_NAT_PUBLIC_IP"

echo "OCI NAT public IP: $OCI_NAT_PUBLIC_IP"

step "Carregando credenciais do PostgreSQL"

POSTGRES_ADMIN_USER="$(require_value "PostgreSQL admin username" BOBHUB_DB_ADMIN_USER)" || exit 1
POSTGRES_PASSWORD="$(require_secret "PostgreSQL admin password" TF_VAR_postgresql_admin_password)" || exit 1
APP_DB_PASSWORD="$(require_secret "BobHub application DB password" BOBHUB_DB_PASSWORD)" || exit 1

export TF_VAR_postgresql_admin_password="$POSTGRES_PASSWORD"

step "Provisionando camada de dados Azure"
run_tf "$AZURE_DIR" init
run_tf "$AZURE_DIR" validate
run_tf "$AZURE_DIR" apply "${TF_AUTO_APPROVE[@]}"

step "Fase 1 concluída"

echo "OCI:   $OCI_DIR"
echo "Azure: $AZURE_DIR"

step "Preparando sessão de port forwarding no Bastion"

APP_PRIVATE_IP="$(trim "$(tf_output "$OCI_DIR" application_instance_private_ip)")"
BASTION_ID="$(trim "$(tf_output "$OCI_DIR" bastion_id)")"

[[ -n "$APP_PRIVATE_IP" ]] || die "Não foi possível obter application_instance_private_ip."
[[ -n "$BASTION_ID" ]] || die "Não foi possível obter bastion_id."

OCI_CONFIG_FILE="${OCI_CONFIG_FILE:-$HOME/.oci/config}"
SSH_PRIVATE_KEY="${OCI_SSH_PRIVATE_KEY:-$HOME/.ssh/bobhub-oci}"
SSH_PUBLIC_KEY="${OCI_SSH_PUBLIC_KEY:-$HOME/.ssh/bobhub-oci.pub}"

[[ -f "$OCI_CONFIG_FILE" ]] || die "Arquivo de configuração OCI não encontrado: $OCI_CONFIG_FILE"
[[ -f "$SSH_PRIVATE_KEY" ]] || die "Chave SSH privada não encontrada: $SSH_PRIVATE_KEY"
[[ -f "$SSH_PUBLIC_KEY" ]] || die "Chave SSH pública não encontrada: $SSH_PUBLIC_KEY"

echo "Application private IP: $APP_PRIVATE_IP"
echo "Bastion ID: $BASTION_ID"

BASTION_JSON="$(oci bastion bastion get \
  --bastion-id "$BASTION_ID" \
  --config-file "$OCI_CONFIG_FILE" \
  --output json)" || die "Falha ao consultar o Bastion."

BASTION_TTL="$(jq -r '.data."max-session-ttl-in-seconds" // empty' <<<"$BASTION_JSON")"
[[ -n "$BASTION_TTL" ]] || die "Não foi possível determinar o TTL máximo da sessão do Bastion."

echo "Bastion session TTL: $BASTION_TTL segundos"

step "Criando sessão de port forwarding no Bastion"

oci bastion session create-port-forwarding \
  --bastion-id "$BASTION_ID" \
  --ssh-public-key-file "$SSH_PUBLIC_KEY" \
  --target-private-ip "$APP_PRIVATE_IP" \
  --target-port 22 \
  --session-ttl "$BASTION_TTL" \
  --display-name "$BASTION_SESSION_NAME" \
  --wait-for-state SUCCEEDED \
  --config-file "$OCI_CONFIG_FILE" \
  --output json >/dev/null || die "Falha ao criar a sessão de port forwarding."

step "Obtendo sessão ativa do Bastion"

SESSIONS_JSON="$(oci bastion session list \
  --bastion-id "$BASTION_ID" \
  --config-file "$OCI_CONFIG_FILE" \
  --all \
  --output json)" || die "Falha ao listar as sessões do Bastion."

SESSION_ID=""

for _ in {1..10}; do
  SESSION_ID="$(jq -r --arg ip "$APP_PRIVATE_IP" --arg name "$BASTION_SESSION_NAME" '
    [.data[]
      | select(."display-name" == $name)
      | select(."lifecycle-state" == "ACTIVE")
      | select(."target-resource-details"."target-resource-private-ip-address" == $ip)]
    | sort_by(."time-created")
    | last
    | .id // empty
  ' <<<"$SESSIONS_JSON")"

  [[ -n "$SESSION_ID" ]] && break
  sleep 3

  SESSIONS_JSON="$(oci bastion session list \
    --bastion-id "$BASTION_ID" \
    --config-file "$OCI_CONFIG_FILE" \
    --all \
    --output json 2>/dev/null || true)"
done

[[ -n "$SESSION_ID" ]] || die "Sessão ativa de port forwarding não encontrada."

echo "Bastion session ID: $SESSION_ID"

step "Limpando túnel SSH antigo"

stop_tunnel() {
  if [[ -f "$TUNNEL_PID_FILE" ]]; then
    local pid
    pid="$(cat "$TUNNEL_PID_FILE" 2>/dev/null || true)"

    if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
      local comm
      comm="$(ps -p "$pid" -o comm= 2>/dev/null | tr -d '[:space:]' || true)"

      if [[ "$comm" == "ssh" ]]; then
        echo "Encerrando túnel SSH antigo (PID $pid)..."
        kill "$pid" 2>/dev/null || true

        for _ in {1..10}; do
          kill -0 "$pid" 2>/dev/null || break
          sleep 0.5
        done

        kill -9 "$pid" 2>/dev/null || true
      else
        die "A porta 2222 pertence a um processo que não é ssh (PID $pid)."
      fi
    fi

    rm -f "$TUNNEL_PID_FILE"
  fi

  if ss -ltn 2>/dev/null | awk 'NR > 1 {print $4}' | grep -q ':2222$'; then
    die "A porta 2222 já está em uso por outro processo."
  fi
}

stop_tunnel

step "Abrindo túnel SSH em 127.0.0.1:2222"

start_tunnel() {
  local attempt pid

  for attempt in 1 2 3; do
    echo "Tentativa $attempt de 3..."

    : >"$TUNNEL_LOG"

    ssh -N \
      -L "127.0.0.1:2222:${APP_PRIVATE_IP}:22" \
      -i "$SSH_PRIVATE_KEY" \
      -o ExitOnForwardFailure=yes \
      -o ServerAliveInterval=30 \
      -o ServerAliveCountMax=3 \
      -o StrictHostKeyChecking=accept-new \
      -o BatchMode=yes \
      -o NumberOfPasswordPrompts=0 \
      -p 22 \
      "${SESSION_ID}@${BASTION_HOST}" >>"$TUNNEL_LOG" 2>&1 &

    pid=$!
    echo "$pid" >"$TUNNEL_PID_FILE"

    sleep 5

    if kill -0 "$pid" 2>/dev/null; then
      TUNNEL_PID="$pid"
      return 0
    fi

    echo "A tentativa $attempt falhou:" >&2
    sed -n '1,20p' "$TUNNEL_LOG" >&2 || true
    rm -f "$TUNNEL_PID_FILE"

    if (( attempt < 3 )); then
      sleep 10
    fi
  done

  return 1
}

TUNNEL_PID=""
start_tunnel || die "Não foi possível estabelecer o túnel SSH após 3 tentativas."

step "Validando túnel SSH local"

TUNNEL_READY=0

for _ in {1..10}; do
  if timeout 2 bash -c '</dev/tcp/127.0.0.1/2222' 2>/dev/null; then
    TUNNEL_READY=1
    break
  fi
  sleep 3
done

if (( ! TUNNEL_READY )); then
  kill "$TUNNEL_PID" 2>/dev/null || true
  die "O túnel SSH em 127.0.0.1:2222 não respondeu."
fi

echo "Túnel SSH pronto (PID $TUNNEL_PID)."

step "Atualizando inventário do Ansible"

mkdir -p "$(dirname "$INVENTORY_FILE")"

cat >"$INVENTORY_FILE" <<EOF
[oci_app]
bobhub-oci ansible_host=127.0.0.1 ansible_port=2222 ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY} ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'
EOF

chmod 600 "$INVENTORY_FILE"

ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[127.0.0.1]:2222" >/dev/null 2>&1 || true

step "Testando conectividade do Ansible"

PING_OUTPUT="$(cd "$ANSIBLE_DIR" && ansible -i inventory/oci.ini oci_app -m ping 2>&1)" || {
  echo "$PING_OUTPUT" >&2
  die "O teste de conectividade do Ansible falhou."
}

echo "$PING_OUTPUT"

grep -q '"ping": "pong"' <<<"$PING_OUTPUT" || die "O Ansible não retornou ping/pong."

echo "Conectividade do Ansible validada."

step "Preparando configuração do banco BobHub"

POSTGRES_FQDN="$(trim "$(tf_output "$AZURE_DIR" postgresql_fqdn)")"
POSTGRES_DATABASE="$(trim "$(tf_output "$AZURE_DIR" postgresql_database_name)")"

[[ -n "$POSTGRES_FQDN" ]] || die "Não foi possível obter postgresql_fqdn."
[[ -n "$POSTGRES_DATABASE" ]] || die "Não foi possível obter postgresql_database_name."

export BOBHUB_DB_HOST="$POSTGRES_FQDN"
export BOBHUB_DB_NAME="$POSTGRES_DATABASE"
export BOBHUB_DB_USER="bobhub_app"
export BOBHUB_DB_PASSWORD="$APP_DB_PASSWORD"
export BOBHUB_DB_ADMIN_USER="$POSTGRES_ADMIN_USER"
export BOBHUB_DB_ADMIN_PASSWORD="$POSTGRES_PASSWORD"

step "Implantando a aplicação BobHub com Ansible"

(cd "$ANSIBLE_DIR" && ansible-playbook -i inventory/oci.ini playbooks/oci-application.yml) || \
  die "A implantação da aplicação com Ansible falhou."

step "Startup do BobHub v0.3 concluído"

echo ""
echo "OCI:"
echo "  Application private IP: $APP_PRIVATE_IP"
echo "  NAT public IP:          $OCI_NAT_PUBLIC_IP"
echo ""
echo "Azure:"
echo "  PostgreSQL:             $POSTGRES_FQDN"
echo "  Database:               $POSTGRES_DATABASE"
echo ""
echo "Bastion:"
echo "  Session ID:             $SESSION_ID"
echo "  Tunnel PID:             $TUNNEL_PID"
echo "  Endpoint:               127.0.0.1:2222"
