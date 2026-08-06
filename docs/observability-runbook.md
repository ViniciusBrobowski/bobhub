# BobHub Observability Runbook

## Objective

This runbook documents how to operate, validate and troubleshoot the BobHub observability stack.

It is intended to be used as an operational guide for starting, stopping, validating and recovering the monitoring and alerting environment.

---

## Stack Overview

The BobHub observability stack is composed of:

| Component | Purpose |
|---|---|
| Prometheus | Metrics collection and alert rule evaluation |
| Grafana | Metrics visualization |
| Node Exporter | Host metrics exporter |
| Alertmanager | Alert routing and notification management |
| Discord Webhook | Alert notification channel |

Current alerting flow:

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

## Service Ports

| Service | Port | URL |
|---|---:|---|
| Grafana | 3000 | http://localhost:3000 |
| Prometheus | 9090 | http://localhost:9090 |
| Node Exporter | 9100 | http://localhost:9100/metrics |
| Alertmanager | 9093 | http://localhost:9093 |

These URLs are intended for local or lab access. Public access details must not be documented here.

---

## File Locations

Main observability files:

```text
docker/observability/docker-compose.yml
docker/prometheus/prometheus.yml
docker/prometheus/alert.rules.yml
docker/alertmanager/alertmanager.yml
docker/alertmanager/discord-webhook.url.example
```

Sensitive file ignored by Git:

```text
docker/alertmanager/discord-webhook.url
```

The real Discord webhook URL must never be committed to the repository.

---

## Start the Stack

Use the BobHub script:

```bash
./scripts/observability/start-observability.sh
```

Or manually:

```bash
cd docker/observability
docker compose up -d
```

Validate containers:

```bash
docker ps
```

Expected containers:

```text
grafana
prometheus
node-exporter
alertmanager
```

---

## Stop the Stack

Use the BobHub script:

```bash
./scripts/observability/stop-observability.sh
```

Or manually:

```bash
cd docker/observability
docker compose down
```

---

## Restart the Stack

Use the BobHub script:

```bash
./scripts/observability/restart-observability.sh
```

Or manually:

```bash
cd docker/observability
docker compose down
docker compose up -d
```

---

## Health Check

Use the BobHub script:

```bash
./scripts/observability/health-check.sh
```

Manual checks:

```bash
docker ps
curl -s http://localhost:9090/-/healthy
curl -s http://localhost:9093/-/healthy
curl -s http://localhost:9100/metrics | head
```

Expected results:

| Check | Expected Result |
|---|---|
| Prometheus health | Healthy response |
| Alertmanager health | Healthy response |
| Node Exporter metrics | Metrics output |
| Containers | Running |

---

## Validate Prometheus Configuration

Use the BobHub validation script:

```bash
./scripts/observability/validate-prometheus.sh
```

Manual validation:

```bash
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

Expected result:

```text
SUCCESS
```

---

## Validate Alertmanager Configuration

Manual validation:

```bash
docker exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml
```

Expected result:

```text
SUCCESS
```

---

## Validate Prometheus to Alertmanager Integration

Check if Prometheus can see Alertmanager:

```bash
curl -s http://localhost:9090/api/v1/alertmanagers | python3 -m json.tool
```

Expected result should include:

```text
http://alertmanager:9093/api/v2/alerts
```

If Alertmanager does not appear, check:

- Prometheus configuration
- Docker Compose network
- Alertmanager container status
- Prometheus container logs

---

## Test Alert Delivery

A simple way to test the alert flow is to stop Node Exporter temporarily.

Stop Node Exporter:

```bash
docker stop node-exporter
```

Wait for the alert rule evaluation period.

Expected result:

```text
Prometheus detects Node Exporter as down
Alertmanager receives the alert
Discord receives a firing notification
```

Start Node Exporter again:

```bash
docker start node-exporter
```

Expected result:

```text
Prometheus detects Node Exporter as available again
Alertmanager sends a resolved notification
Discord receives a resolved notification
```

---

## Important Alert Rule

The first validated BobHub alert is:

```text
BobHubNodeExporterDown
```

Purpose:

```text
Detect when Prometheus cannot scrape Node Exporter.
```

Alert rule file:

```text
docker/prometheus/alert.rules.yml
```

---

## Logs

Check Prometheus logs:

```bash
docker logs prometheus --tail 50
```

Check Alertmanager logs:

```bash
docker logs alertmanager --tail 50
```

Check Node Exporter logs:

```bash
docker logs node-exporter --tail 50
```

Check Grafana logs:

```bash
docker logs grafana --tail 50
```

---

## Common Issues and Fixes

### Alertmanager does not start

Check configuration:

```bash
docker logs alertmanager --tail 100
docker exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml
```

Common causes:

- Invalid YAML syntax
- Unsupported field name
- Template error
- Missing Discord webhook file
- Permission issue on webhook file

---

### Discord alert is not sent

Check:

```bash
docker logs alertmanager --tail 100
```

Validate that the webhook file exists:

```bash
ls -la docker/alertmanager/discord-webhook.url
```

Validate file permission:

```bash
chmod 644 docker/alertmanager/discord-webhook.url
```

The webhook file must be readable by the Alertmanager container.

---

### Prometheus does not load alert rules

Validate Prometheus config:

```bash
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

Check if the alert rules file is mounted correctly in Docker Compose:

```text
../prometheus/alert.rules.yml:/etc/prometheus/alert.rules.yml:ro
```

Check if `prometheus.yml` includes:

```yaml
rule_files:
  - /etc/prometheus/alert.rules.yml
```

---

### Prometheus cannot reach Alertmanager

Check Prometheus configuration:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093
```

Check containers:

```bash
docker ps
```

Check Docker Compose network:

```bash
cd docker/observability
docker compose ps
```

---

### Node Exporter is not being scraped

Check target status in Prometheus:

```text
http://localhost:9090/targets
```

Expected target:

```text
node-exporter:9100
```

Check container:

```bash
docker ps | grep node-exporter
```

Check metrics endpoint:

```bash
curl -s http://localhost:9100/metrics | head
```

---

## Security Notes

Do not commit sensitive files.

Ignored sensitive file:

```text
docker/alertmanager/discord-webhook.url
```

Versioned example file:

```text
docker/alertmanager/discord-webhook.url.example
```

The repository must not include:

- Discord webhook URLs
- Tokens
- Secrets
- Credentials
- Public IP addresses
- Private infrastructure details

---

## Recovery Procedure

If the observability stack is not working:

1. Check container status:

```bash
docker ps
```

2. Check logs:

```bash
docker logs prometheus --tail 50
docker logs alertmanager --tail 50
docker logs node-exporter --tail 50
```

3. Validate Prometheus:

```bash
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

4. Validate Alertmanager:

```bash
docker exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml
```

5. Restart the stack:

```bash
./scripts/observability/restart-observability.sh
```

6. Re-test alert delivery:

```bash
docker stop node-exporter
docker start node-exporter
```

---

## Operational Checklist

Use this checklist after changes to the observability stack:

- [ ] Docker Compose configuration is valid
- [ ] Prometheus configuration is valid
- [ ] Alertmanager configuration is valid
- [ ] Containers are running
- [ ] Prometheus targets are up
- [ ] Alertmanager is visible to Prometheus
- [ ] Discord webhook file is present locally
- [ ] Discord webhook file is not committed
- [ ] Firing alert was tested
- [ ] Resolved alert was tested
- [ ] Documentation was updated

---

## Related Scripts

```text
scripts/observability/start-observability.sh
scripts/observability/stop-observability.sh
scripts/observability/restart-observability.sh
scripts/observability/validate-prometheus.sh
scripts/observability/health-check.sh
```

---

## Related Documentation

```text
docs/monitoring.md
docs/infrastructure-report.md
docs/bobhub-cli.md
```

---

## Version Goal

This runbook is part of the BobHub v0.1 foundation.

It documents the minimum operational knowledge required to run and recover the current observability stack.