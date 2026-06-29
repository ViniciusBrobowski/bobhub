#!/bin/bash

set -e

cd "$(git rev-parse --show-toplevel)/docker/observability"

echo "Parando stack de observabilidade..."
docker compose stop

echo
echo "Stack de observabilidade parada."
