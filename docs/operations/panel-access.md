# BobHub Control Panel — acesso via Cloudflare

Este documento registra como o painel do BobHub é publicado na VPS, como o
acesso é autenticado na borda e quais verificações devem ser feitas depois de
qualquer mudança.

## Endpoint

```text
https://ambiente.kernelcoffe.online
```

O acesso local continua disponível por túnel SSH em
`127.0.0.1:8090`. A porta `8090` não é exposta publicamente.

## Topologia

```text
Internet
  -> Cloudflare Access (bobhub.cloudflareaccess.com)
  -> Cloudflare Tunnel
  -> Traefik, entrypoint interno tunnel (:8081)
  -> http://172.23.0.1:8090
  -> bobhub-panel.service (host, 0.0.0.0:8090)
```

O Traefik publica os serviços somente no entrypoint interno `tunnel`. Os
entrypoints públicos `web` (`:80`) e `websecure` (`:443`) não têm router para o
painel; por isso, um acesso direto ao IP da VPS retorna `404`.

## Autenticação

O painel usa a mesma proteção de borda dos outros serviços publicados:

- aplicação **self-hosted** no Cloudflare Access;
- domínio `ambiente.kernelcoffe.online`;
- equipe `bobhub.cloudflareaccess.com`;
- política equivalente à do Grafana.

O token interno do painel continua sendo exigido nas rotas `/api/*` e é
regenerado a cada reinício do processo. Depois de reiniciar o painel, recarregue
a página com `Ctrl+F5`.

### Restrição de IP

A restrição de IP é opcional e deve ser aplicada apenas quando o IP do
administrador for fixo.

Opção recomendada, no nível da zona:

```text
(http.host eq "ambiente.kernelcoffe.online" and not ip.src in {SEU_IP})
```

Ação: **Block**.

Alternativa no Cloudflare Access: manter a política do Grafana e adicionar
`Require` de IP **na mesma policy**:

```text
Include: e-mail/grupo permitido
Require: faixa de IP do administrador
```

Não crie duas policies separadas (uma de e-mail e outra de IP): policies
diferentes são combinadas com **OR**, o que permitiria acesso só por IP ou só
por e-mail.

Se o IP for dinâmico, não fixe uma allowlist sem um processo de atualização. O
Access com e-mail/MFA já fornece autenticação forte; um IP fixo mal mantido pode
bloquear o próprio administrador.

## Configuração no host

### Serviço systemd

O serviço do painel escuta em todas as interfaces, mas a UFW restringe a porta à
rede Docker do proxy e ao loopback:

```ini
[Unit]
Description=BobHub Control Panel
After=network-online.target

[Service]
EnvironmentFile=-/etc/bobhub/panel.env
ExecStart=/opt/bobhub/panel/bobhub-panel --host 0.0.0.0 --port 8090 --no-browser --repo /opt/bobhub/bobhub
Restart=on-failure
User=vinicius
Group=vinicius

[Install]
WantedBy=multi-user.target
```

O bind em `0.0.0.0` é necessário para que o container do Traefik alcance o
serviço pela bridge. O `hostGuard` do painel é voltado ao modo local
(`127.0.0.1`); quando o bind é externo, a fronteira de segurança passa a ser a
UFW e o Cloudflare Access.

### UFW

Regra aplicada:

```bash
sudo ufw allow from 172.23.0.0/16 to any port 8090 proto tcp
```

A regra libera apenas a rede `bobhub-proxy`. O acesso público à `8090` continua
negado pelo padrão da UFW. O loopback permanece disponível para o túnel SSH.

### Túnel SSH de contingência

```bash
ssh -L 8090:127.0.0.1:8090 <usuario>@<VPS_IP>
```

Depois, abra `http://127.0.0.1:8090`.

## Configuração no Traefik

### Rota do painel

Arquivo: `/opt/bobhub/traefik/config/panel.yml`

```yaml
http:
  routers:
    bobhub-panel:
      rule: "Host(`ambiente.kernelcoffe.online`)"
      entryPoints:
        - tunnel
      service: bobhub-panel

  services:
    bobhub-panel:
      loadBalancer:
        servers:
          - url: "http://172.23.0.1:8090"
```

O endereço `172.23.0.1` é o gateway da rede Docker `bobhub-proxy`, onde o
Traefik está conectado.

### Mount no compose

O arquivo precisa estar montado no container do Traefik:

```yaml
- ./config/panel.yml:/etc/traefik/dynamic/panel.yml:ro
```

O provider de arquivos do Traefik observa o diretório e recarrega a rota
automaticamente. Se o mount for alterado, recrie o container:

```bash
sudo docker compose -f /opt/bobhub/traefik/compose.yml up -d
```

## Configuração no Cloudflare

### Ordem segura

1. Criar a aplicação no Cloudflare Access e, se aplicável, a regra de IP.
2. Adicionar ou corrigir o Public Hostname no túnel.
3. Só então testar o painel.

Trocar o serviço do túnel para `http://traefik:8081` antes de criar o Access
deixa o painel público, porque o token do painel é entregue na página inicial.

### Public Hostname

No túnel existente:

```text
Hostname: ambiente.kernelcoffe.online
Service:  http://traefik:8081
```

Não use `http://traefik:80`: esse é o entrypoint `web`, que não tem router para o
painel e responde `404 page not found`.

O Public Hostname cria ou reutiliza o registro DNS `ambiente` como CNAME
proxied para o túnel. O DNS já resolve para a Cloudflare; a rota do túnel é que
precisa apontar para o entrypoint correto.

### Access App

```text
Tipo:     Self-hosted
Nome:     BobHub Panel
Domínio:  ambiente.kernelcoffe.online
Equipe:   bobhub.cloudflareaccess.com
Policy:   mesma política do Grafana
```

## Validação

### URL pública

Sem sessão do Access, deve retornar redirecionamento para o login:

```bash
curl -sS -I https://ambiente.kernelcoffe.online
```

Esperado:

```text
HTTP/1.1 302 Found
Location: https://bobhub.cloudflareaccess.com/cdn-cgi/access/login/...
```

Depois do login, o painel deve responder `200`.

### Origem direta

O IP da VPS não deve permitir bypass:

```bash
curl -k -sS -o /dev/null -w '%{http_code}\n' \
  --resolve ambiente.kernelcoffe.online:443:<VPS_IP> \
  https://ambiente.kernelcoffe.online/
```

Esperado: `404`, pois não existe router público para o painel.

### Porta 8090

De uma máquina externa:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' -m 6 http://<VPS_IP>:8090/
```

Esperado: timeout ou falha de conexão. Um `200` a partir da própria VPS pode ser
loopback e não prova exposição externa.

### Painel no host

```bash
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8090/
```

Esperado: `200`.

### Traefik internamente

```bash
docker run --rm --network bobhub-proxy curlimages/curl:latest \
  -sS -o /dev/null -w '%{http_code}\n' \
  -H 'Host: ambiente.kernelcoffe.online' \
  http://traefik:8081/
```

Esperado: `200`.

## Diagnóstico rápido

| Sintoma | Causa provável | Ação |
| --- | --- | --- |
| `404 page not found` na URL pública | Public Hostname aponta para `http://traefik:80` | Alterar para `http://traefik:8081` |
| `502` na URL pública | Painel parado, UFW bloqueando ou Traefik não alcança `172.23.0.1:8090` | Verificar `systemctl status bobhub-panel`, regra da UFW e logs do Traefik |
| `403` na URL pública | Regra WAF de IP bloqueando | Revisar `ip.src` e a regra de IP |
| Redireciona para o Access e volta ao login | Política/cookie de sessão do Access | Revisar a aplicação e a política do Access |
| Painel `200` no SSH, mas não pelo domínio | Rota do túnel ou Access | Validar Public Hostname e Access App |
| Token inválido após reinício | Token novo gerado pelo painel | Recarregar com `Ctrl+F5` |

## Rollback

### Cloudflare

1. Remover o Public Hostname `ambiente.kernelcoffe.online` do túnel.
2. Remover a aplicação de Access e a regra de IP, se criadas.
3. Remover o registro DNS `ambiente`, se não for mais necessário.

### Traefik

1. Restaurar o backup do compose criado antes da alteração
   (`/opt/bobhub/traefik/compose.yml.bak-*`).
2. Remover `/opt/bobhub/traefik/config/panel.yml` do diretório de configuração.
3. Recriar o container do Traefik.

### Painel

1. Restaurar o backup do unit
   (`/etc/systemd/system/bobhub-panel.service.bak-*`).
2. Executar `sudo systemctl daemon-reload`.
3. Reiniciar o serviço com `sudo systemctl restart bobhub-panel`.
4. Remover a regra da UFW, se a porta não precisar mais ser acessada pela bridge.

O painel volta ao bind `127.0.0.1:8090` e o túnel SSH continua sendo o acesso de
contingência.

## Arquivos e backups

| Item | Caminho |
| --- | --- |
| Rota do painel | `/opt/bobhub/traefik/config/panel.yml` |
| Compose do Traefik | `/opt/bobhub/traefik/compose.yml` |
| Unit do painel | `/etc/systemd/system/bobhub-panel.service` |
| Backup do compose | `/opt/bobhub/traefik/compose.yml.bak-*` |
| Backup do unit | `/etc/systemd/system/bobhub-panel.service.bak-*` |

Os backups têm timestamp e não contêm credenciais.

## Referências

- [Painel BobHub](../../panel/README.md)
- [Vault do painel](../../scripts/vault/README.md)
- [README principal](../../README.md)
