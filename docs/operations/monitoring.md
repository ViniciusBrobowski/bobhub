# Monitoring Documentation

## Overview

O BobHub utiliza o Uptime Kuma como plataforma principal de monitoramento.

O objetivo é validar a disponibilidade da infraestrutura, conectividade VPN e serviços críticos do ambiente.

---

## Monitoring Platform

### Uptime Kuma

Responsável pelo monitoramento centralizado do ambiente.

Funções:

* Verificação de disponibilidade
* Monitoramento de hosts
* Monitoramento de serviços
* Monitoramento de túneis VPN
* Histórico de incidentes

---

## Monitored Components

### HQ

| Monitor     | Tipo |
| ----------- | ---- |
| VPS         | Ping |
| Portainer   | HTTP |
| Uptime Kuma | HTTP |

---

### Site A

| Monitor      | Tipo        |
| ------------ | ----------- |
| pfSense-A    | Ping        |
| Tunnel-A     | Ping        |
| Ubuntu-A     | Ping        |
| SSH Ubuntu-A | TCP Port 22 |

---

### Site B

| Monitor      | Tipo        |
| ------------ | ----------- |
| pfSense-B    | Ping        |
| Tunnel-B     | Ping        |
| Ubuntu-B     | Ping        |
| SSH Ubuntu-B | TCP Port 22 |

---

## Monitoring Goals

O ambiente deve permitir a identificação rápida de:

* Queda da VPS
* Falha de conectividade VPN
* Indisponibilidade das filiais
* Falha de hosts monitorados
* Falha de serviços críticos

---

## Future Monitoring Stack

Planejamento de evolução:

### Observability

* Grafana
* Prometheus
* Loki

### Metrics

* CPU
* Memória
* Disco
* Rede

### Logs

* Logs centralizados
* Dashboards operacionais
* Histórico de eventos

---

## Current Status

Status da plataforma:

* Uptime Kuma Operacional
* Monitoramento Centralizado Operacional
* Túneis VPN Monitorados
* Hosts das Filiais Monitorados
