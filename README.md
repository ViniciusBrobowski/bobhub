# 🚀 BobHub

Personal Infrastructure, Observability and DevOps Lab focused on Linux, WireGuard, Docker, Automation and Cloud Technologies.

> Jornada prática de evolução de Infraestrutura para DevOps através da construção de um ambiente corporativo simulado.

---

# 📖 Sobre o Projeto

O BobHub nasceu inicialmente como um laboratório para estudos de VPN Site-to-Site utilizando WireGuard.

Com o avanço do ambiente, o projeto evoluiu para uma arquitetura centralizada baseada em um Datacenter (HQ) hospedado em uma VPS pública, conectado a múltiplas filiais simuladas através de túneis WireGuard.

O objetivo é criar um ambiente prático para desenvolvimento de habilidades em:

* Infraestrutura Linux
* Redes e VPNs
* Observabilidade
* Automação
* DevOps
* Inteligência Artificial aplicada à Operação

---

# 🏗️ Arquitetura Atual

## HQ (Datacenter)

Servidor VPS Linux responsável por centralizar serviços, monitoramento e conectividade entre as filiais.

### Serviços

* Docker
* Portainer
* Nginx Proxy Manager
* Uptime Kuma
* WireGuard Hub

### Rede

```text
10.255.255.1/24
```

---

## Filial A

### Rede

```text
10.10.40.0/24
```

### Componentes

* pfSense-A
* Ubuntu Client A

### WireGuard

```text
10.255.255.2
```

---

## Filial B

### Rede

```text
10.20.40.0/24
```

### Componentes

* pfSense-B
* Ubuntu Client B

### WireGuard

```text
10.255.255.3
```

---

# 🌐 Topologia

```text
                    HQ
              10.255.255.1
                     |
        +------------+------------+
        |                         |
        |                         |
   Site A                    Site B
10.10.40.0/24           10.20.40.0/24
```

---

# 📊 Monitoramento

Atualmente o ambiente possui monitoramento centralizado através do Uptime Kuma.

### Itens Monitorados

* VPS
* Portainer
* Uptime Kuma
* pfSense-A
* pfSense-B
* Tunnel Site A
* Tunnel Site B
* Ubuntu Client A
* Ubuntu Client B
* SSH Ubuntu Client A
* SSH Ubuntu Client B

---

# 🔐 Segurança

Implementações realizadas:

* Autenticação SSH por chave pública
* Usuário administrativo dedicado
* UFW (Uncomplicated Firewall)
* Backups de configuração
* Snapshots periódicos
* WireGuard para comunicação segura entre sites

---

# 🛠️ Tecnologias Utilizadas

### Infraestrutura

* Debian
* Ubuntu Server
* pfSense

### Containers

* Docker
* Portainer

### Redes

* WireGuard
* VPN Hub-and-Spoke

### Observabilidade

* Uptime Kuma

### Proxy Reverso

* Nginx Proxy Manager

---

# 🎯 Roadmap

## Fase 1 — Infraestrutura

* [x] VPS Linux
* [x] Docker
* [x] Portainer
* [x] WireGuard
* [x] VPN Hub-and-Spoke

---

## Fase 2 — Observabilidade

* [x] Uptime Kuma
* [ ] Grafana
* [ ] Prometheus
* [ ] Loki

---

## Fase 3 — DevOps

* [X] Git
* [X] GitHub
* [ ] Infraestrutura como Código
* [ ] CI/CD
* [ ] Ansible

---

## Fase 4 — Automação

* [ ] n8n
* [ ] Workflows Operacionais
* [ ] Integração com Microsoft 365
* [ ] Integração com Freshservice

---

## Fase 5 — Inteligência Artificial

* [ ] OpenWebUI
* [ ] Ollama
* [ ] ChatOps
* [ ] Assistente Operacional

---

# 📂 Estrutura Planejada do Repositório

```text
bobhub/
│
├── README.md
│
├── docs/
│   ├── architecture.md
│   ├── network.md
│   ├── monitoring.md
│   └── roadmap.md
│
├── docker/
│
├── wireguard/
│
├── diagrams/
│
└── scripts/
```

---

# 📚 Objetivo de Aprendizado

O BobHub é utilizado como ambiente prático para evolução profissional da área de Infraestrutura para DevOps, permitindo experimentar tecnologias, arquiteturas e processos utilizados em ambientes corporativos modernos.

O foco principal do projeto é desenvolver experiência prática em:

* Linux
* Containers
* Redes
* Observabilidade
* Automação
* Infraestrutura como Código
* DevOps

---

# 🚦 Status Atual

**Status:** 🟢 Operacional

### Ambiente Atual

* HQ Online
* Site A Online
* Site B Online
* VPN Hub-and-Spoke Operacional
* Monitoramento Centralizado Operacional

---

*"A melhor forma de aprender continua sendo construir."*
