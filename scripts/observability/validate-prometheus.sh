#!/bin/bash

set -e

cd "$(git rev-parse --show-toplevel)"

echo "===================================="
echo " BobHub Prometheus Validator"
echo "===================================="
echo

echo "[1/2] Validando prometheus.yml..."
docker run --rm \
    --entrypoint promtool \
    -v "$(realpath docker/prometheus)":/etc/prometheus \
    prom/prometheus \
    check config /etc/prometheus/prometheus.yml

echo "[2/2] Validando regras de alerta..."
docker run --rm \
    --entrypoint promtool \
    -v "$(realpath docker/prometheus)":/etc/prometheus \
    prom/prometheus \
    check rules /etc/prometheus/alerts/infrastructure.yml

echo
echo "Prometheus e alertas validados com sucesso."