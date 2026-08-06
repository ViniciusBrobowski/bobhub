# Architecture Documentation

## Overview

O BobHub utiliza uma arquitetura centralizada baseada no modelo Hub-and-Spoke.

Uma VPS pública atua como Datacenter Central (HQ), hospedando os serviços compartilhados e concentrando as conexões VPN das filiais.

---

## High Level Architecture

```text
                    Internet
                        |
                        |
                  HQ (VPS)
                        |
        +---------------+---------------+
        |                               |
        |                               |
     Site A                         Site B
```

---

## HQ (Datacenter)

### Infrastructure

* Debian Linux
* Docker

### Services

* Portainer
* Nginx Proxy Manager
* Uptime Kuma
* WireGuard Hub

### Responsibilities

* Centralização do monitoramento
* Gerenciamento de containers
* Conectividade VPN entre sites
* Hospedagem de serviços compartilhados

---

## Site A

### Infrastructure

* pfSense
* Ubuntu Server

### Responsibilities

* Simulação de filial corporativa
* Testes de conectividade
* Validação de VPN Site-to-Site

---

## Site B

### Infrastructure

* pfSense
* Ubuntu Server

### Responsibilities

* Simulação de filial corporativa
* Testes de conectividade
* Validação de VPN Site-to-Site

---

## Monitoring Architecture

```text
Uptime Kuma
     |
     +-- VPS
     +-- pfSense-A
     +-- pfSense-B
     +-- Ubuntu-A
     +-- Ubuntu-B
     +-- VPN Tunnels
```

---

## Future Architecture

Plataforma planejada para evolução do ambiente:

### Observability

* Grafana
* Prometheus
* Loki

### Automation

* n8n
* Workflows Operacionais

### DevOps

* Git
* CI/CD
* Ansible

### Artificial Intelligence

* OpenWebUI
* Ollama
* ChatOps

```
```
