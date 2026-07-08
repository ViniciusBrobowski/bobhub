# BobHub Checkpoint — Observability Alerting

## Status

Completed.

## Date

2026-07-08

---

## Overview

This checkpoint closes the first BobHub observability and alerting sprint.

The goal was to create a functional monitoring and alerting flow using Prometheus, Node Exporter, Alertmanager and Discord notifications.

---

## Completed Scope

Implemented components:

- Grafana
- Prometheus
- Node Exporter
- Alertmanager
- Prometheus alert rules
- Discord alert notifications

---

## Alert Flow

```text
Node Exporter
  ↓
Prometheus
  ↓
Alertmanager
  ↓
Discord
```

---

## Completed Cards

- #7 Add Alertmanager to observability stack
- #8 Connect Prometheus to Alertmanager
- #9 Configure Discord alert notifications

---

## Technical Validations

### Containers

Validated running containers:

```text
grafana
prometheus
node-exporter
alertmanager
```

Alertmanager status:

```text
Up (healthy)
```

---

### Prometheus Health

Command:

```bash
curl http://localhost:9090/-/healthy
```

Result:

```text
Prometheus Server is Healthy.
```

---

### Alertmanager Health

Command:

```bash
curl http://localhost:9093/-/healthy
```

Result:

```text
OK
```

---

### Node Exporter Metrics

Command:

```bash
curl -s http://localhost:9100/metrics | head
```

Result:

```text
Node Exporter metrics returned successfully.
```

---

### Prometheus to Alertmanager Integration

Command:

```bash
curl -s http://localhost:9090/api/v1/alertmanagers | python3 -m json.tool
```

Result:

```json
{
  "status": "success",
  "data": {
    "activeAlertmanagers": [
      {
        "url": "http://alertmanager:9093/api/v2/alerts"
      }
    ],
    "droppedAlertmanagers": []
  }
}
```

---

### Alertmanager Configuration

Command:

```bash
docker exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml
```

Result:

```text
SUCCESS
```

---

### Prometheus Configuration

Command:

```bash
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

Result:

```text
SUCCESS
```

---

## Alert Test

A real alert was triggered by stopping the Node Exporter container.

Command:

```bash
docker stop node-exporter
```

Expected behavior:

```text
Prometheus detects Node Exporter as down.
Alertmanager receives the alert.
Discord receives the firing notification.
```

After validation, Node Exporter was started again.

Command:

```bash
docker start node-exporter
```

Expected behavior:

```text
Prometheus detects Node Exporter as up.
Alertmanager resolves the alert.
Discord receives the resolved notification.
```

Both firing and resolved notifications were successfully received in Discord.

---

## Issues Found and Fixed

### Alertmanager template issue

Problem:

```text
function "Labels" not defined
```

Cause:

The Discord message template was using an unsafe label reference format.

Fix:

Used `index` in the Alertmanager template.

Example:

```text
{{ index .Labels "alertname" }}
```

---

### Discord webhook mount issue

Problem:

```text
open /etc/alertmanager/discord-webhook.url: no such file or directory
```

Cause:

The Docker Compose volume path had a typo.

Fix:

Corrected the volume mount path.

Expected mount:

```yaml
- ../alertmanager/discord-webhook.url:/etc/alertmanager/discord-webhook.url:ro
```

---

### Discord webhook permission issue

Problem:

```text
Permission denied
```

Cause:

The webhook file had permission `600`, but Alertmanager runs as user `nobody`.

Fix:

```bash
chmod 644 docker/alertmanager/discord-webhook.url
```

---

## Security Notes

The real Discord webhook URL is not versioned.

Ignored file:

```text
docker/alertmanager/discord-webhook.url
```

Versioned example file:

```text
docker/alertmanager/discord-webhook.url.example
```

---

## Current Result

BobHub now has a working observability and alerting pipeline with Discord notifications for both firing and resolved alerts.

This checkpoint confirms that the first observability sprint is complete.