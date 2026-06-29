#!/bin/bash

set -e

cd "$(git rev-parse --show-toplevel)"

OBSERVABILITY_DIR="docker/observability"

echo "======================================="
echo " BobHub Observability Health Check"
echo "======================================="
echo

echo "[1/5] Verificando containers da stack..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "prometheus|grafana|node-exporter" || echo "Nenhum container da stack encontrado."

echo 
echo "[2/5] Verificando Prometheus HTTP..."
if curl -s --max-time 5 http://localhost:9090/-/healthy | grep -qi "prometheus"; then
    echo "Prometheus: OK"
else
    echo "Prometheus: FALHA"
fi

echo
echo "[3/5] Verificando Grafana HTTP..."
if curl -s --max-time 5 http://localhost:3000/login > /dev/null; then
    echo "Grafana: OK"
else
    echo "Grafana: FALHA"
fi

echo
echo "[4/5] Verificando targets do Prometheus..."
if curl -s --max-time 5 http://localhost:9090/api/v1/targets > /tmp/bobhub-prometheus-targets.json; then
    echo "Prometheus Targets API: OK"
else
    echo "Prometheus Targets API: FALHA"
fi

echo
echo "[5/5] Validando regras do Prometheus..."
docker run --rm \
    --entrypoint promtool \
    -v "$(realpath docker/prometheus)":/etc/prometheus \
    prom/prometheus \
    check rules /etc/prometheus/alerts/infrastructure.yml

echo
echo "======================================="
echo "Health check concluído."
echo "======================================="