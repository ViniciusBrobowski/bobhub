#!/bin/bash

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

pause() {
    echo
    read -p "Pressione [Enter] para continuar..."
}

header() {
    clear
    echo "========================================"
    echo "            BobHub CLI"
    echo "========================================"
    echo "Infrastructure & DevOps Lab"
    echo
    echo "========================================"
    echo
    echo "Repositório: $(basename "$REPO_ROOT")"
    echo "Branch     : $(git branch --show-current)"
    echo
}

git_menu() {
    while true; do
        header
        echo "Git"
        echo
        echo "1) Git Status"
        echo "2) Commit and push"
        echo "3) Git log"
        echo "0) Back"
        echo
        read -rp "Choice: " choice

        case "$choice" in
            1)
                git status
                pause
                ;;
            2)
                read -rp "Commit message: " commit_message
                read -rp "Issue number (optional): " issue_number
                
                if [ -n "$issue_number" ]; then
                    ./scripts/git/git-commit-push.sh "$commit_message" "$issue_number"
                else
                    ./scripts/git/git-commit-push.sh "$commit_message"
                fi

                pause
                ;;
            3)
                git log --oneline --decorate -10
                pause
                ;;
            0)
                break
                ;;
            *)
                echo "Invalid option."
                pause
                ;;
        esac
    done
}

observability_menu() {
    while true; do
        header
        echo "Observability"
        echo
        echo "1) Start stack"
        echo "2) Stop stack"
        echo "3) Restart stack"
        echo "4) Validate Prometheus"
        echo "5) Health check"
        echo "0) Back"
        echo
        read -rp "Choice: " choice

        case "$choice" in
            1)
                ./scripts/observability/start-observability.sh
                pause
                ;;
            2)
                ./scripts/observability/stop-observability.sh
                pause
                ;;
            3)
                ./scripts/observability/restart-observability.sh
                pause
                ;;
            4)
                ./scripts/observability/validate-prometheus.sh
                pause
                ;;
            5)
                ./scripts/observability/health-check.sh
                pause
                ;;
            0)
                break
                ;;
            *)
                echo "Invalid option."
                pause
                ;;
        esac
    done
}

health_menu() {
    while true; do
        header
        echo "Health"
        echo
        echo "1) Observability health check"
        echo "2) Validate Prometheus"
        echo "0) Back"
        echo
        read -rp "Choice: " choice

        case "$choice" in
            1)
                ./scripts/observability/health-check.sh
                pause
                ;;
            2)
                ./scripts/observability/validate-prometheus.sh
                pause
                ;;
            0)
                break
                ;;
            *)
                echo "Invalid option."
                pause
                ;;
        esac
    done
}

inventory_menu() {
    while true; do
        header
        echo "Inventory"
        echo
        echo "1) Generate infrastructure inventory"
        echo "2) Show generated inventory path"
        echo "0) Back"
        echo 
        read -rp "Choice: " choice

        case "$choice" in
            1)
                ./scripts/inventory/generate-inventory.sh
                pause
                ;;
            2)
                echo "Inventory file:"
                echo "$REPO_ROOT/docs/inventory.md"
                pause
                ;;
            0)
                break
                ;;
            *)
                echo "Invalid option."
                pause
                ;;
        esac
    done    
}

main_menu() {
    while true; do
        header
        echo "Main Menu"
        echo
        echo "1) Git"
        echo "2) Observability"
        echo "3) Health"
        echo "4) Inventory"
        echo "0) Exit"
        echo
        read -rp "Choice: " choice

        case "$choice" in
            1)
                git_menu
                ;;
            2)
                observability_menu
                ;;
            3)
                health_menu
                ;;
            4)
                inventory_menu
                ;;
            0)
                echo "Bye."
                exit 0
                ;;
            *)
                echo "Invalid option."
                pause
                ;;
        esac
    done
}

main_menu