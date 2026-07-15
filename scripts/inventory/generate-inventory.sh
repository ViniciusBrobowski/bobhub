#!/usr/bin/env bash

set -euo pipefail

OUTPUT_FILE="docs/inventory.md"
GENERATED_AT="$(date '+%Y-%m-%d %H:%M:%S')"

mkdir -p docs

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

write_section() {
    local title="$1"
    echo
    echo "## $title"
    echo
}

{
    echo "# BobHub Infrastructure Inventory"
    echo
    echo "Generated at: $GENERATED_AT"
    echo
    echo "---"

    write_section "Host Information"

    echo "| Item | Value |"
    echo "|---|---|"
    echo "| Hostname | $(hostname) |"
    echo "| Kernel | $(uname -r) |"
    echo "| Architecture | $(uname -m) |"

    if command_exists hostnamectl; then
        OS_NAME="$(hostnamectl 2>/dev/null | grep 'Operating System' | sed 's/Operating System: //')"
        echo "| Operating System | ${OS_NAME:-Unknown} |"
    else
        echo "| Operating System | Unknown |"
    fi

    echo "| Uptime | $(uptime -p 2>/dev/null || echo 'Unknown') |"

    write_section "CPU"

    echo '```text'
    if command_exists lscpu; then
        lscpu | grep -E 'Model name|Socket|Core|CPU\(s\)|Thread|MHz|Architecture' || true
    else
        echo "lscpu not available"
    fi
    echo '```'

    write_section "Memory"

    echo '```text'
    if command_exists free; then
        free -h
    else
        echo "free command not available"
    fi
    echo '```'

    write_section "Disk Usage"

    echo '```text'
    if command_exists df; then
        df -h
    else
        echo "df command not available"
    fi
    echo '```'

    write_section "Block Devices"

    echo '```text'
    if command_exists lsblk; then
        lsblk
    else
        echo "lsblk command not available"
    fi
    echo '```'

    write_section "Network"

    echo "| Item | Value |"
    echo "|---|---|"
    echo "| Host IPs | $(hostname -I 2>/dev/null | xargs || echo 'Unknown') |"

    write_section "Docker"

    if command_exists docker; then
        echo "| Item | Value |"
        echo "|---|---|"
        echo "| Docker Version | $(docker --version | sed 's/,//g') |"

    if docker compose version >/dev/null 2>&1; then
        echo "| Docker Compose Version | $(docker compose version | sed 's/,//g') |"
    else
        echo "| Docker Compose Version | Not available |"
    fi

    write_section "Running Containers"

    echo '```text'
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    echo '```'
    
    write_section "All Containers"

    echo '```text'
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    echo '```'

    write_section "Docker Networks"
    echo '```text'
    docker network ls
    echo '```'

    write_section "Docker Volumes"
    echo '```text'
    docker volume ls
    echo '```'

else 
    echo "Docker is not installed or not available."
fi    

write_section "BobHub Observability Endpoints"

echo "| Service | URL | Expected Result |"
echo "|---|---|---|"
echo "| Grafana | http://localhost:3000 | Web UI |"
echo "| Prometheus | http://localhost:9090 | Health endpoint |"
echo "| Alertmanager | http://localhost:9093 | Health endpoint |"
echo "| Node Exporter | http://localhost:9100/metrics | Metrics endpoint |"

write_section "Validation Commands"

echo '```bash'
echo "curl -s http://localhost:9090/-/healthy"
echo "curl -s http://localhost:9093/-/healthy"
echo "curl -s http://localhost:9100/metrics | head"
echo "curl -s http://localhost:9090/api/v1/alertmanagers | python3 -m json.tool"
echo '```'

} > "$OUTPUT_FILE"

echo "Inventory generated at: $OUTPUT_FILE"
