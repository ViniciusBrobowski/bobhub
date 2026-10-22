#!/usr/bin/env bash
#
# Configura o Vault para o painel BobHub.
#
# O que este script faz:
#   1. Garante KV v2 no mount "secret/".
#   2. Habilita o auth method AppRole.
#   3. Cria/atualiza a policy "bobhub-panel" (leitura apenas).
#   4. Grava os segredos do laboratório em secret/data/bobhub/lab.
#   5. Grava OCI config/chave/SSH em secret/data/bobhub/cloud (se existirem).
#   6. Cria/atualiza o role AppRole "bobhub-panel".
#   7. Gera role-id e secret-id em ~/.config/bobhub (0600).
#
# Uso:
#   export VAULT_ADDR=http://127.0.0.1:8200
#   vault login
#   ./scripts/vault/setup-bobhub-panel.sh
#
# Opcional (arquivos OCI/SSH fora dos caminhos padrão):
#   OCI_CONFIG_FILE=/caminho/config \
#   OCI_API_KEY_FILE=/caminho/oci_api_key.pem \
#   OCI_SSH_PRIVATE_KEY=/caminho/bobhub-oci \
#   OCI_SSH_PUBLIC_KEY=/caminho/bobhub-oci.pub \
#   BOBHUB_SEED_DIR=/caminho/seed \
#   ./scripts/vault/setup-bobhub-panel.sh
#
# Rode como o usuário "vinicius" (não com sudo/root). O Vault Agent roda como
# root e lê os arquivos de AppRole em /home/vinicius/.config/bobhub.
#
set -Eeuo pipefail

VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
export VAULT_ADDR

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bobhub"
ROLE_ID_FILE="$CONFIG_DIR/vault-role-id"
SECRET_ID_FILE="$CONFIG_DIR/vault-secret-id"

step() { printf '\n==> %s\n' "$*"; }
warn() { printf 'AVISO: %s\n' "$*" >&2; }
die()  { printf 'ERRO: %s\n' "$*" >&2; exit 1; }

if [[ "$(id -u)" -eq 0 ]]; then
  die "Rode como 'vinicius', sem sudo. O token do Vault fica em ~/.vault-token."
fi

command -v vault >/dev/null 2>&1 || die "vault CLI não encontrado"
command -v jq >/dev/null 2>&1 || die "jq não encontrado"
command -v curl >/dev/null 2>&1 || die "curl não encontrado"
command -v python3 >/dev/null 2>&1 || die "python3 não encontrado"

step "Verificando conexão e token do Vault"
vault status >/dev/null 2>&1 || die "Vault inacessível em $VAULT_ADDR"
vault token lookup >/dev/null 2>&1 || die "Faça 'vault login' primeiro (com VAULT_ADDR=$VAULT_ADDR)."
echo "Vault: $VAULT_ADDR"

step "Garantindo KV v2 em secret/"
if ! vault secrets list -format=json | jq -e '.["secret/"]' >/dev/null; then
  vault secrets enable -path=secret -version=2 kv >/dev/null
  echo "KV v2 habilitado em secret/"
else
  version="$(vault secrets list -format=json | jq -r '.["secret/"].options.version // "1"')"
  [[ "$version" == "2" ]] || die "O mount 'secret/' existe, mas não é KV v2 (version=$version)."
  echo "KV v2 já habilitado"
fi

step "Garantindo auth method AppRole"
if ! vault auth list -format=json | jq -e '.["approle/"]' >/dev/null; then
  vault auth enable approle >/dev/null
  echo "AppRole habilitado"
else
  echo "AppRole já habilitado"
fi

step "Escrevendo policy bobhub-panel"
vault policy write bobhub-panel - >/dev/null <<'EOF'
path "secret/data/bobhub/*" {
  capabilities = ["read"]
}
path "secret/metadata/bobhub/*" {
  capabilities = ["read", "list"]
}
EOF
echo "policy bobhub-panel gravada"

step "Segredos do laboratório"
ADMIN_USER="${BOBHUB_DB_ADMIN_USER:-}"
if [[ -z "$ADMIN_USER" ]]; then
  read -r -p "PostgreSQL admin username: " ADMIN_USER
fi
[[ -n "$ADMIN_USER" ]] || die "admin username vazio"

ADMIN_PASSWORD="${TF_VAR_postgresql_admin_password:-}"
if [[ -z "$ADMIN_PASSWORD" ]]; then
  read -r -s -p "PostgreSQL admin password: " ADMIN_PASSWORD; echo
fi
[[ -n "$ADMIN_PASSWORD" ]] || die "admin password vazio"

APP_PASSWORD="${BOBHUB_DB_PASSWORD:-}"
if [[ -z "$APP_PASSWORD" ]]; then
  read -r -s -p "Senha do usuário da aplicação: " APP_PASSWORD; echo
fi
[[ -n "$APP_PASSWORD" ]] || die "app password vazio"

NAT_IP="${TF_VAR_oci_nat_public_ip:-}"

# Monta o JSON via python para não colocar segredo em argv.
LAB_PAYLOAD="$(
  ADMIN_USER="$ADMIN_USER" \
  ADMIN_PASSWORD="$ADMIN_PASSWORD" \
  APP_PASSWORD="$APP_PASSWORD" \
  NAT_IP="$NAT_IP" \
  python3 - <<'PY'
import json
import os

data = {
    "admin_user": os.environ["ADMIN_USER"],
    "admin_password": os.environ["ADMIN_PASSWORD"],
    "app_password": os.environ["APP_PASSWORD"],
}
nat_ip = os.environ.get("NAT_IP", "")
if nat_ip:
    data["nat_ip"] = nat_ip

print(json.dumps({"data": data}))
PY
)"

VAULT_TOKEN_VALUE="${VAULT_TOKEN:-$(cat "$HOME/.vault-token")}"
write_kv() {
  local path="$1"
  local payload="$2"
  printf '%s' "$payload" | curl -fsS \
    -H "X-Vault-Token: $VAULT_TOKEN_VALUE" \
    -H "Content-Type: application/json" \
    --request POST --data-binary @- \
    "$VAULT_ADDR/v1/$path" >/dev/null
}

write_kv "secret/data/bobhub/lab" "$LAB_PAYLOAD"
echo "segredos do laboratório gravados em secret/data/bobhub/lab"

step "Segredos OCI/SSH"
OCI_CONFIG_FILE="${OCI_CONFIG_FILE:-$HOME/.oci/config}"
OCI_API_KEY_FILE="${OCI_API_KEY_FILE:-$HOME/.oci/oci_api_key.pem}"
OCI_SSH_PRIVATE_KEY="${OCI_SSH_PRIVATE_KEY:-$HOME/.ssh/bobhub-oci}"
OCI_SSH_PUBLIC_KEY="${OCI_SSH_PUBLIC_KEY:-$HOME/.ssh/bobhub-oci.pub}"

missing=0
for f in "$OCI_CONFIG_FILE" "$OCI_API_KEY_FILE" "$OCI_SSH_PRIVATE_KEY" "$OCI_SSH_PUBLIC_KEY"; do
  if [[ ! -f "$f" ]]; then
    warn "não encontrado: $f"
    missing=1
  fi
done

CLOUD_WRITTEN=0
if [[ "$missing" -eq 0 ]]; then
  tmpdir="$(mktemp -d)"
  chmod 700 "$tmpdir"
  trap 'rm -rf "$tmpdir"' EXIT

  sed -E 's/\r$//' "$OCI_CONFIG_FILE" \
    | sed -E 's#^[[:space:]]*key_file[[:space:]]*=.*#key_file=/home/vinicius/.oci/oci_api_key.pem#' \
    > "$tmpdir/config"
  sed -E 's/\r$//' "$OCI_API_KEY_FILE" > "$tmpdir/oci_api_key.pem"
  sed -E 's/\r$//' "$OCI_SSH_PRIVATE_KEY" > "$tmpdir/bobhub-oci"
  sed -E 's/\r$//' "$OCI_SSH_PUBLIC_KEY" > "$tmpdir/bobhub-oci.pub"

  CLOUD_PAYLOAD="$(
    jq -n \
      --rawfile oci_config "$tmpdir/config" \
      --rawfile oci_api_key "$tmpdir/oci_api_key.pem" \
      --rawfile oci_ssh_private_key "$tmpdir/bobhub-oci" \
      --rawfile oci_ssh_public_key "$tmpdir/bobhub-oci.pub" \
      '{data:{
        oci_config:$oci_config,
        oci_api_key:$oci_api_key,
        oci_ssh_private_key:$oci_ssh_private_key,
        oci_ssh_public_key:$oci_ssh_public_key
      }}'
  )"

  write_kv "secret/data/bobhub/cloud" "$CLOUD_PAYLOAD"
  CLOUD_WRITTEN=1
  echo "segredos OCI/SSH gravados em secret/data/bobhub/cloud"
else
  warn "cloud secrets NÃO gravados; o Vault Agent vai falhar nos templates OCI/SSH até você rodar de novo."
fi

step "Criando/atualizando o role AppRole bobhub-panel"
vault write auth/approle/role/bobhub-panel \
  token_policies=bobhub-panel \
  token_ttl=1h \
  token_max_ttl=4h \
  secret_id_ttl=720h \
  bind_secret_id=true >/dev/null
echo "role AppRole bobhub-panel configurado"

step "Gerando role-id e secret-id"
mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"
vault read -field=role_id auth/approle/role/bobhub-panel/role-id \
  | tr -d '\n' > "$ROLE_ID_FILE"
vault write -f -field=secret_id auth/approle/role/bobhub-panel/secret-id \
  | tr -d '\n' > "$SECRET_ID_FILE"
chmod 600 "$ROLE_ID_FILE" "$SECRET_ID_FILE"
echo "role-id:   $ROLE_ID_FILE"
echo "secret-id: $SECRET_ID_FILE"

if [[ -n "${BOBHUB_SEED_DIR:-}" && "$CLOUD_WRITTEN" -eq 1 && -d "$BOBHUB_SEED_DIR" ]]; then
  rm -rf "$BOBHUB_SEED_DIR"
  echo "staging removido: $BOBHUB_SEED_DIR"
fi

cat <<'EOF'

==> Pronto

Ative o Agent e reinicie o painel:

  sudo systemctl enable --now vault-agent
  sudo systemctl restart bobhub-panel

Verifique (sem expor segredos):

  sudo systemctl status vault-agent --no-pager
  sudo journalctl -u vault-agent -n 30 --no-pager
  sudo systemctl status bobhub-panel --no-pager
  ls -l /etc/bobhub/panel.env /home/vinicius/.oci /home/vinicius/.ssh/bobhub-oci*

Para rotacionar o secret-id, rode este script novamente e reinicie o Agent.
EOF
