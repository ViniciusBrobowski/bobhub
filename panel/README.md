# BobHub Control Panel

Painel local para iniciar, parar e observar o laboratório **BobHub v0.3 (OCI + Azure)**
sem precisar decorar a ordem dos comandos de Terraform, OCI CLI, Azure CLI, SSH e Ansible.

O backend é um binário **Go** (somente biblioteca padrão) que serve o front end embutido,
expõe uma API JSON + SSE e executa os scripts existentes:

- `scripts/cloud/start-v03-lab.ps1`
- `scripts/cloud/stop-v03-lab.ps1`

Nenhuma dependência de Node, Python ou framework web é necessária para o painel.

---

## Requisitos

| Requisito | Observação |
| --- | --- |
| Windows 10/11 | Os scripts de ciclo de vida usam PowerShell, WSL e `Get-NetTCPConnection`. |
| Go 1.22+ | Apenas para compilar. O binário gerado é autocontido. |
| PowerShell 5.1+ | `powershell.exe` já vem no Windows. |
| Terraform | Com acesso aos workspaces HCP `bobhub-v03-oci-dr` e `bobhub-v03-azure-data`. |
| Azure CLI (`az`) | Autenticado em uma assinatura com permissão de provisionamento. |
| OCI CLI (`oci`) | Configurado em `~/.oci/config`. |
| OpenSSH (`ssh`) | Usado pelo túnel do Bastion. |
| WSL + Ansible | `ansible-playbook` disponível dentro do WSL. |

O painel mostra o estado de cada ferramenta na tela e não inicia nada se os pré-requisitos
básicos estiverem ausentes.

---

## Como executar

Na raiz do repositório:

```powershell
.\panel\start.ps1
```

O script compila o binário na primeira execução (ou quando os fontes mudarem) e abre:

```text
http://127.0.0.1:8090
```

Opções:

```powershell
.\panel\start.ps1 -Port 8091
.\panel\start.ps1 -NoBrowser
.\panel\start.ps1 -Rebuild
```

Para compilar manualmente:

```powershell
cd panel
go build -trimpath -ldflags "-s -w" -o bin\bobhub-panel.exe .
```

Para executar sem o script:

```powershell
.\panel\bin\bobhub-panel.exe --port 8090
```

Flags do binário:

| Flag | Padrão | Descrição |
| --- | --- | --- |
| `--port` | `8090` | Porta HTTP local. |
| `--host` | `127.0.0.1` | Endereço de escuta. Manter local por segurança. |
| `--repo` | autodetectado | Caminho da raiz do BobHub. |
| `--no-browser` | `false` | Não abre o navegador automaticamente. |

---

## Segredos via ambiente (Vault)

O painel aceita que as credenciais sejam injetadas como variáveis de ambiente no
próprio processo. Isso permite usar **Vault Agent** (ou systemd `EnvironmentFile`)
sem digitar senhas na interface e sem gravá-las em disco pelo painel.

| Variável | Uso |
| --- | --- |
| `BOBHUB_DB_ADMIN_USER` | Usuário admin do PostgreSQL. |
| `TF_VAR_postgresql_admin_password` | Senha admin do PostgreSQL (start e stop). |
| `BOBHUB_DB_PASSWORD` | Senha do app `bobhub_app` (start). |
| `TF_VAR_oci_nat_public_ip` | IP público do NAT Gateway (opcional). |

Precedência: **valor digitado no formulário > variável de ambiente**. Campos
deixados em branco usam o valor do ambiente; o painel mostra apenas *quais*
segredos estão disponíveis, nunca os valores.

Exemplo de template do Vault Agent:

```hcl
template {
  destination = "/etc/bobhub/panel.env"
  perms       = "0600"

  contents = <<EOT
BOBHUB_DB_ADMIN_USER={{ with secret "secret/data/bobhub/lab" }}{{ .Data.data.admin_user }}{{ end }}
TF_VAR_postgresql_admin_password={{ with secret "secret/data/bobhub/lab" }}{{ .Data.data.admin_password }}{{ end }}
BOBHUB_DB_PASSWORD={{ with secret "secret/data/bobhub/lab" }}{{ .Data.data.app_password }}{{ end }}
{{ with secret "secret/data/bobhub/lab" }}{{ if .Data.data.nat_ip }}TF_VAR_oci_nat_public_ip={{ .Data.data.nat_ip }}{{ end }}{{ end }}
EOT
}
```

O Agent também renderiza as credenciais de nuvem usadas pelos scripts:

```hcl
template {
  destination = "/home/vinicius/.config/bobhub/azure-sp.json"
  perms       = "0600"
  user        = "vinicius"
  group       = "vinicius"

  contents = <<EOT
{{ with secret "secret/data/bobhub/azure" }}{{ .Data.data.azure_sp_json }}{{ end }}
EOT
}

template {
  destination = "/home/vinicius/.terraform.d/credentials.tfrc.json"
  perms       = "0600"
  user        = "vinicius"
  group       = "vinicius"

  contents = <<EOT
{{ with secret "secret/data/bobhub/terraform" }}{{ .Data.data.hcp_credentials_json }}{{ end }}
EOT
}
```

O primeiro é lido por `scripts/cloud/azure-login.sh` quando a sessão do Azure
expira; o segundo é lido pelo Terraform para o remote state no HCP.

Serviço systemd correspondente:

```ini
[Unit]
Description=BobHub Control Panel
After=network-online.target

[Service]
EnvironmentFile=/etc/bobhub/panel.env
ExecStart=/opt/bobhub/panel/bin/bobhub-panel --host 127.0.0.1 --port 8090 --no-browser
Restart=on-failure
User=bobhub

[Install]
WantedBy=multi-user.target
```

> **Limitação atual:** o binário Go é portátil, mas os scripts de ciclo de vida
> usam PowerShell, WSL e `Get-NetTCPConnection`. Enquanto eles não forem portados
> para Bash, a execução precisa acontecer em um host Windows. O suporte a
> variáveis de ambiente já prepara o terreno para a versão na VPS.

---

## O que a tela faz

### Iniciar ambiente

1. Valida as credenciais preenchidas (ou usa as variáveis de ambiente) e envia ao
   backend apenas em memória.
2. Executa `start-v03-lab.ps1 -NonInteractive` com:
   - `BOBHUB_DB_ADMIN_USER`
   - `TF_VAR_postgresql_admin_password`
   - `BOBHUB_DB_PASSWORD`
   - `TF_VAR_oci_nat_public_ip` (quando conhecido)
3. O script roda `terraform init/validate/apply`, cria a sessão de port forwarding
   no Bastion, abre o túnel SSH na porta `2222`, atualiza o inventário Ansible e
   executa o playbook da aplicação.
4. A saída é transmitida em tempo real para o console do painel.

Como o modo é não interativo, os `terraform apply` recebem `-auto-approve`.
As senhas **não** são gravadas em disco, nem passam por argumentos de linha de comando.

### Parar ambiente

1. Pede confirmação explícita (a tela avisa que Azure e OCI serão destruídos).
2. Executa `stop-v03-lab.ps1 -NonInteractive` com:
   - `TF_VAR_postgresql_admin_password`
   - `TF_VAR_oci_nat_public_ip` (vindo do status do Terraform ou do próprio formulário)
3. O script encerra o túnel SSH, destrói o Azure PostgreSQL e depois a infraestrutura OCI,
   usando `terraform destroy -auto-approve`.

### Status

O painel consulta, com cache curto:

- ferramentas locais (`terraform`, `az`, `oci`, `ssh`, `wsl`, `ansible`);
- autenticação do Azure (`az account show`);
- outputs do Terraform do OCI (instância, NAT, Bastion e Load Balancer);
- outputs do Terraform do Azure (FQDN e database do PostgreSQL);
- túnel TCP em `127.0.0.1:2222`;
- endpoints públicos da aplicação via Load Balancer: `/health`, `/whoami` e `/db-health`;
- comportamento do WAF: uma requisição com `X-BobHub-WAF-Test: block` deve retornar `403`.

### Cancelar

O botão **Cancelar execução** encerra a árvore de processos do PowerShell com
`taskkill /PID <pid> /T /F`. O Terraform pode deixar recursos parcialmente criados;
rodar **Iniciar** novamente reconcilia o estado, e **Parar** faz a limpeza.

### Login do Azure

O botão **Abrir `az login`** abre uma janela separada do PowerShell com `az login`,
sem bloquear o painel.

---

## Arquitetura

```text
┌───────────────────────────┐
│ Navegador (localhost)     │
│ HTML + CSS + JS embutidos │
└─────────────┬─────────────┘
              │ JSON + SSE + token local
┌─────────────▼─────────────┐
│ bobhub-panel.exe (Go)     │
│ net/http + os/exec        │
└─────────────┬─────────────┘
              │ powershell.exe -NonInteractive
┌─────────────▼─────────────────────────────────────────────┐
│ start-v03-lab.ps1 / stop-v03-lab.ps1                      │
│ terraform ↔ az ↔ oci ↔ ssh ↔ wsl(ansible)                │
└───────────────────────────────────────────────────────────┘
```

Arquivos:

```text
panel/
├── main.go              # servidor HTTP, status, execução, SSE
├── main_test.go         # testes unitários dos helpers
├── go.mod
├── start.ps1            # compila (se necessário) e executa
├── README.md
└── static/
    ├── index.html
    ├── styles.css
    ├── app.js
    └── favicon.svg
```

---

## API local

Todas as rotas `/api/*` exigem o token gerado em cada inicialização do painel.
O token é injetado no HTML e enviado pelo front end no cabeçalho
`X-BobHub-Token` (ou como `?token=` no `EventSource`).

| Método | Rota | Descrição |
| --- | --- | --- |
| `GET` | `/api/health` | Verificação simples do processo. Não exige token. |
| `GET` | `/api/status?refresh=1` | Status consolidado (o parâmetro invalida o cache). |
| `GET` | `/api/events?token=...` | Stream SSE com logs e mudanças de execução. |
| `POST` | `/api/start` | Inicia o laboratório. |
| `POST` | `/api/stop` | Destrói o laboratório. |
| `POST` | `/api/cancel` | Cancela a execução ativa. |
| `POST` | `/api/az-login` | Abre uma janela com `az login`. |
| `POST` | `/api/waf-test` | Testa a regra do WAF pelo Load Balancer. |
| `POST` | `/api/logs/clear` | Limpa o histórico de logs do servidor. |

Exemplo de corpo para `/api/start`:

```json
{
  "admin_user": "bobhubadmin",
  "admin_password": "...",
  "app_password": "..."
}
```

Para `/api/stop`, `admin_password` é obrigatório (formulário ou `TF_VAR_postgresql_admin_password`);
`nat_ip` é opcional.

Todos os campos podem ser omitidos quando a variável de ambiente correspondente
estiver presente no processo do painel. O status expõe apenas booleanos em
`secrets`, nunca os valores.

---

## Segurança

- O servidor escuta apenas em `127.0.0.1` por padrão.
- O middleware valida o cabeçalho `Host` para evitar DNS rebinding quando o bind é local.
- Um token aleatório de 256 bits é gerado a cada execução e exigido nas rotas sensíveis.
- CSP restritiva, sem CORS e sem recursos externos.
- Senhas ficam somente na memória do processo e do navegador; não são persistidas.
- Credenciais injetadas por ambiente (Vault) nunca são enviadas ao navegador; a API
  informa apenas se cada uma está presente.
- As senhas são removidas dos logs antes de serem transmitidas (`********`).
- `POST` é usado para todas as ações que alteram o ambiente.

> O painel executa comandos destrutivos por design. Não o exponha em redes públicas.
> Se precisar acessar de outra máquina, use um túnel SSH e mantenha o token em segredo.

---

## Troubleshooting

**Go não encontrado**

Instale o Go 1.22+ e abra um novo terminal para atualizar o `PATH`:

```powershell
winget install --id GoLang.Go -e
```

**Porta 8090 ocupada**

```powershell
.\panel\start.ps1 -Port 8091
```

**Azure offline**

Clique em **Abrir `az login`** ou rode `az login` no terminal e depois **Atualizar**.

**`load_balancer_public_ip` aparece como `—`**

O painel usa o output do Terraform e, quando ele ainda não existe no state,
consulta `terraform state show` para ler `ip_address_details`. Se continuar
vazio, verifique se o Load Balancer existe no state e se o Terraform está
autenticado no HCP.

**O stream SSE não conecta**

Use `http://127.0.0.1:8090/?nosse=1` para desabilitar o SSE e manter apenas o
polling de status a cada 12 segundos. Isso ajuda a isolar problemas de proxy ou
extensões do navegador.

**WAF retorna algo diferente de 403**

Verifique a regra `X-BobHub-WAF-Test` no WAF do OCI e se o Load Balancer está
apontando para o backend correto. O teste usa `/health` com o cabeçalho
`X-BobHub-WAF-Test: block`.

**Cancelamento deixou recursos pela metade**

Execute **Parar ambiente** para destruir o que existe; em seguida **Iniciar**
reconcilia o state do Terraform.

**Túnel SSH cai depois de um tempo**

A sessão do Bastion tem TTL limitado. Rode **Iniciar ambiente** novamente para
criar uma nova sessão e reiniciar o túnel.

---

## Desenvolvimento

```powershell
cd panel
go vet ./...
go test ./...
go build -o bin\bobhub-panel.exe .
```

O binário embute `static/` com `//go:embed`; após alterar HTML/CSS/JS, recompile
ou use `.\panel\start.ps1 -Rebuild`.
