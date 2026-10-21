# Vault do painel BobHub

Este diretório contém o setup do Vault usado pelo painel e pelo ciclo de vida
do laboratório v0.3.

## Pré-requisitos

- Vault initialized e unsealed em `http://127.0.0.1:8200`.
- CLI `vault`, `jq`, `curl` e `python3` na VPS.
- Token com permissão de administração (root token ou policy equivalente).
- Rodar como o usuário `vinicius` (não com `sudo`).

## 1. Login no Vault

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault login
```

O token fica em `~/.vault-token` (0600). Não é necessário colar o token em
nenhum arquivo do repositório nem no painel.

## 2. Rodar o setup

```bash
cd /opt/bobhub/bobhub
./scripts/vault/setup-bobhub-panel.sh
```

O script pergunta o usuário admin do PostgreSQL, a senha do admin e a senha do
usuário da aplicação. Ele cria:

- KV v2 em `secret/` (se ainda não existir).
- AppRole em `auth/approle/`.
- Policy `bobhub-panel` com leitura apenas em `secret/data/bobhub/*`.
- `secret/data/bobhub/lab`:
  - `admin_user`
  - `admin_password`
  - `app_password`
  - `nat_ip` (opcional)
- `secret/data/bobhub/cloud` (se os arquivos existirem):
  - `oci_config`
  - `oci_api_key`
  - `oci_ssh_private_key`
  - `oci_ssh_public_key`
- Role AppRole `bobhub-panel`.
- `~/.config/bobhub/vault-role-id` e `~/.config/bobhub/vault-secret-id` (0600).

## 3. Arquivos OCI/SSH

Por padrão o script lê:

```text
~/.oci/config
~/.oci/oci_api_key.pem
~/.ssh/bobhub-oci
~/.ssh/bobhub-oci.pub
```

Se os arquivos estiverem em outro lugar:

```bash
OCI_CONFIG_FILE=/caminho/config \
OCI_API_KEY_FILE=/caminho/oci_api_key.pem \
OCI_SSH_PRIVATE_KEY=/caminho/bobhub-oci \
OCI_SSH_PUBLIC_KEY=/caminho/bobhub-oci.pub \
BOBHUB_SEED_DIR=/caminho/seed \
./scripts/vault/setup-bobhub-panel.sh
```

O `key_file` do config OCI é reescrito para
`/home/vinicius/.oci/oci_api_key.pem`. Se `BOBHUB_SEED_DIR` for informado e os
segredos forem gravados com sucesso, o diretório de staging é removido.

## 4. Ativar o Agent e reiniciar o painel

```bash
sudo systemctl enable --now vault-agent
sudo systemctl restart bobhub-panel
```

O Agent renderiza:

```text
/etc/bobhub/panel.env
/home/vinicius/.oci/config
/home/vinicius/.oci/oci_api_key.pem
/home/vinicius/.ssh/bobhub-oci
/home/vinicius/.ssh/bobhub-oci.pub
/home/vinicius/.config/bobhub/azure-sp.json
/home/vinicius/.terraform.d/credentials.tfrc.json
```

## 5. Verificar

```bash
sudo systemctl status vault-agent --no-pager
sudo journalctl -u vault-agent -n 40 --no-pager
sudo systemctl status bobhub-panel --no-pager
ls -l /etc/bobhub/panel.env
ls -l /home/vinicius/.oci /home/vinicius/.ssh/bobhub-oci*
```

O painel não expõe segredos no browser; ele só usa as variáveis de ambiente
carregadas pelo systemd.

## 6. Rotação

- **SecretID do AppRole:** rode o setup novamente e reinicie o Agent.
- **Senhas do banco:** atualize o KV, reinicie o Agent (para re-renderizar
  `panel.env`) e reinicie o painel.
- **Chaves OCI/SSH:** substitua os arquivos, rode o setup novamente e reinicie
  o Agent.

## 7. Migração do service principal e do HCP Terraform

Depois que o Azure SP e o HCP Terraform já estiverem funcionando, grave os dois
no Vault:

```bash
cd /opt/bobhub/bobhub
./scripts/vault/migrate-cloud-secrets.sh
sudo systemctl restart vault-agent
```

O script lê:

- `~/.config/bobhub/azure-sp.json`
- `~/.terraform.d/credentials.tfrc.json`

e grava:

- `secret/data/bobhub/azure` → campo `azure_sp_json`
- `secret/data/bobhub/terraform` → campo `hcp_credentials_json`

A policy `bobhub-panel` já permite leitura em `secret/data/bobhub/*`. O Agent
renderiza os dois arquivos em `0600` com owner `vinicius`. O helper
`scripts/cloud/azure-login.sh` usa o JSON do SP para renovar a sessão do Azure
quando o token em cache expira; o Terraform lê o token do HCP no arquivo de
credenciais.

## Segurança

- O Vault está publicado apenas em `127.0.0.1:8200` no host, mas ainda está na
  rede Docker `bobhub-proxy`. Recomenda-se removê-lo dessa rede para que apenas
  o host acesse a API.
- O painel escuta em `127.0.0.1:8090`; o acesso externo deve ser por túnel SSH
  (`ssh -L 8090:127.0.0.1:8090 vinicius@189.126.106.82`) ou por Cloudflare
  Access/Traefik com autenticação.
- Nunca commitar `terraform.tfstate`, `terraform.tfvars`, chaves PEM ou o
  `ansible/inventory/oci.ini`.
