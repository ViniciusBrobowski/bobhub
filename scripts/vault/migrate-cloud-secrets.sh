#!/usr/bin/env bash
#
# Migra o service principal do Azure e o token do HCP Terraform para o Vault.
#
# Uso:
#   export VAULT_ADDR=http://127.0.0.1:8200
#   vault login
#   cd /opt/bobhub/bobhub
#   ./scripts/vault/migrate-cloud-secrets.sh
#
# Requer:
#   - Vault acessível em VAULT_ADDR
#   - token em ~/.vault-token (ou VAULT_TOKEN)
#   - ~/.config/bobhub/azure-sp.json (0600)
#   - ~/.terraform.d/credentials.tfrc.json (0600)
#
# Grava:
#   secret/data/bobhub/azure      campo azure_sp_json
#   secret/data/bobhub/terraform  campo hcp_credentials_json
#
# A policy "bobhub-panel" já permite leitura em secret/data/bobhub/*.
# O script não imprime segredos e não reinicia o Agent.

set -Eeuo pipefail

VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
export VAULT_ADDR

AZURE_SP_FILE="${BOBHUB_AZURE_SP_FILE:-$HOME/.config/bobhub/azure-sp.json}"
HCP_CRED_FILE="${BOBHUB_HCP_CREDENTIALS_FILE:-$HOME/.terraform.d/credentials.tfrc.json}"

step() { printf '\n==> %s\n' "$*"; }
warn() { printf 'AVISO: %s\n' "$*" >&2; }
die()  { printf 'ERRO: %s\n' "$*" >&2; exit 1; }

if [[ "$(id -u)" -eq 0 ]]; then
  die "Rode como 'vinicius', sem sudo. O token do Vault fica em ~/.vault-token."
fi

for cmd in vault jq curl python3; do
  command -v "$cmd" >/dev/null 2>&1 || die "$cmd não encontrado"
done

[[ -r "$AZURE_SP_FILE" ]] || die "não encontrei $AZURE_SP_FILE"
[[ -r "$HCP_CRED_FILE" ]] || die "não encontrei $HCP_CRED_FILE"

for f in "$AZURE_SP_FILE" "$HCP_CRED_FILE"; do
  mode="$(stat -c '%a' "$f" 2>/dev/null || echo '?')"
  [[ "$mode" == "600" ]] || warn "$f está com permissões $mode (esperado 600)"
done

jq -e '
  (.appId | type == "string" and length > 0) and
  (.password | type == "string" and length > 0) and
  (.tenant | type == "string" and length > 0) and
  (.subscriptionId | type == "string" and length > 0)
' "$AZURE_SP_FILE" >/dev/null \
  || die "JSON do service principal inválido/incompleto"

jq -e '.credentials["app.terraform.io"].token | type == "string" and length > 0' \
  "$HCP_CRED_FILE" >/dev/null \
  || die "token do HCP Terraform não encontrado em $HCP_CRED_FILE"

step "Verificando conexão e token do Vault"
vault status >/dev/null 2>&1 || die "Vault inacessível em $VAULT_ADDR"
vault token lookup >/dev/null 2>&1 || die "Faça 'vault login' primeiro (VAULT_ADDR=$VAULT_ADDR)."
echo "Vault: $VAULT_ADDR"

TOKEN_VALUE="${VAULT_TOKEN:-$(cat "$HOME/.vault-token")}"
write_kv() {
  local path="$1"
  local payload="$2"
  printf '%s' "$payload" | curl -fsS \
    -H "X-Vault-Token: $TOKEN_VALUE" \
    -H "Content-Type: application/json" \
    --request POST --data-binary @- \
    "$VAULT_ADDR/v1/$path" >/dev/null
}

step "Migrando service principal do Azure"
AZURE_JSON="$(jq -c . "$AZURE_SP_FILE")"
AZURE_PAYLOAD="$(
  AZURE_JSON="$AZURE_JSON" python3 - <<'PY'
import json
import os

print(json.dumps({"data": {"azure_sp_json": os.environ["AZURE_JSON"]}}))
PY
)"
write_kv "secret/data/bobhub/azure" "$AZURE_PAYLOAD"
unset AZURE_JSON AZURE_PAYLOAD
echo "gravado: secret/data/bobhub/azure (campo azure_sp_json)"

step "Migrando token do HCP Terraform"
HCP_JSON="$(jq -c . "$HCP_CRED_FILE")"
HCP_PAYLOAD="$(
  HCP_JSON="$HCP_JSON" python3 - <<'PY'
import json
import os

print(json.dumps({"data": {"hcp_credentials_json": os.environ["HCP_JSON"]}}))
PY
)"
write_kv "secret/data/bobhub/terraform" "$HCP_PAYLOAD"
unset HCP_JSON HCP_PAYLOAD
echo "gravado: secret/data/bobhub/terraform (campo hcp_credentials_json)"

step "Pronto"
cat <<'EOF'

Os segredos estão no Vault. Para o Agent renderizar os arquivos, rode:

  sudo systemctl restart vault-agent
  sudo systemctl status vault-agent --no-pager
  sudo journalctl -u vault-agent -n 30 --no-pager

Depois confira, sem imprimir valores:

  ls -l ~/.config/bobhub/azure-sp.json ~/.terraform.d/credentials.tfrc.json
  jq -r 'keys[]' ~/.config/bobhub/azure-sp.json
  jq -r '.credentials | keys[]' ~/.terraform.d/credentials.tfrc.json

Os arquivos continuam em 0600, mas agora são renderizados pelo Agent a partir
do Vault. Não os edite manualmente.
EOF
