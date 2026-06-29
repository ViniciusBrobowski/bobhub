#!/bin/bash

set -e

cd "$(git rev-parse --show-toplevel)/docker/observability"

echo "Reiniciando stack de observabilidade..."
docker compose restart

echo
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "prometheus|grafana|node-exporter" || true

echo
echo "Stack de observabilidade reiniciada."
