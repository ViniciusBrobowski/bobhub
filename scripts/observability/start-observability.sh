#!/bin/bash

set -e

cd "$(git rev-parse --show-toplevel)/docker/observability"

echo "====================================="
echo " Starting BobHub Observability Stack"
echo "====================================="
echo

echo "Iniciando stack de observabilidade..."
docker compose up -d

echo
echo "Containers da stack:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "prometheus|grafana|node-exporter" || true

echo
echo "Stack de observabilidade iniciada."
