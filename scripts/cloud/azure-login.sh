#!/usr/bin/env bash
#
# Reautentica o Azure CLI com o service principal renderizado pelo Vault Agent.
#
# Usado pelos scripts de start/stop quando a sessão em cache expira. O arquivo
# padrão é ~/.config/bobhub/azure-sp.json (0600), com os campos appId, password,
# tenant e subscriptionId. Nenhum valor é impresso.

set -Eeuo pipefail

SP_FILE="${BOBHUB_AZURE_SP_FILE:-$HOME/.config/bobhub/azure-sp.json}"

die() { printf 'ERRO: %s\n' "$*" >&2; exit 1; }

[[ -r "$SP_FILE" ]] || die "service principal não encontrado/legível: $SP_FILE"
command -v az >/dev/null 2>&1 || die "az não encontrado"
command -v jq >/dev/null 2>&1 || die "jq não encontrado"

APP_ID="$(jq -r '.appId // empty' "$SP_FILE")"
CLIENT_SECRET="$(jq -r '.password // empty' "$SP_FILE")"
TENANT_ID="$(jq -r '.tenant // empty' "$SP_FILE")"

[[ -n "$APP_ID" && -n "$CLIENT_SECRET" && -n "$TENANT_ID" ]] \
  || die "service principal incompleto em $SP_FILE"

az login \
  --service-principal \
  --username "$APP_ID" \
  --password "$CLIENT_SECRET" \
  --tenant "$TENANT_ID" \
  --output none >/dev/null

unset CLIENT_SECRET
