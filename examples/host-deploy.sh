#!/usr/bin/env bash

# Deployment script for host-based arr-stack configuration
# This script should be used in your host configuration repository

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Configuration
HOST_NAME="${1:-arr-lxc}"  # Default to arr-lxc, or pass as argument
FLAKE_PATH="."

check_host_config() {
    log "Checking host configuration for '$HOST_NAME'..."
    
    if ! nix flake show | grep -q "nixosConfigurations.$HOST_NAME"; then
        error "Host configuration '$HOST_NAME' not found in flake"
        log "Available configurations:"
        nix flake show | grep nixosConfigurations || echo "None found"
        exit 1
    fi
    
    success "Host configuration '$HOST_NAME' found"
}

update_inputs() {
    log "Updating flake inputs..."
    nix flake update
    success "Flake inputs updated"
}

build_config() {
    log "Building configuration for '$HOST_NAME'..."
    nix build ".#nixosConfigurations.$HOST_NAME.config.system.build.toplevel"
    success "Configuration built successfully"
}

deploy_config() {
    log "Deploying configuration for '$HOST_NAME'..."
    sudo nixos-rebuild switch --flake ".#$HOST_NAME"
    success "Configuration deployed successfully"
}

check_services() {
    log "Checking arr-stack services..."
    
    local services=("plex")
    
    # Check if additional services are enabled
    if systemctl list-unit-files | grep -q "sonarr.service"; then
        services+=("sonarr")
    fi
    if systemctl list-unit-files | grep -q "radarr.service"; then
        services+=("radarr")
    fi
    if systemctl list-unit-files | grep -q "prowlarr.service"; then
        services+=("prowlarr")
    fi
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            success "$service is running"
        else
            warn "$service is not running"
            log "Starting $service..."
            sudo systemctl start "$service"
        fi
    done
}

show_status() {
    log "System Status for '$HOST_NAME':"
    echo "=================================="
    
    # Show system info
    echo -e "\n${BLUE}System Info:${NC}"
    echo "Hostname: $(hostname)"
    echo "NixOS Version: $(nixos-version)"
    echo "Uptime: $(uptime -p)"
    
    # Show running containers
    echo -e "\n${BLUE}Running Containers:${NC}"
    if command -v podman &> /dev/null; then
        sudo -u media podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No containers running"
    else
        echo "Podman not available"
    fi
    
    # Show service status
    echo -e "\n${BLUE}Service Status:${NC}"
    for service in plex sonarr radarr prowlarr; do
        if systemctl list-unit-files | grep -q "${service}.service"; then
            status=$(systemctl is-active "$service" || echo "inactive")
            echo "$service: $status"
        fi
    done
    
    # Show open ports
    echo -e "\n${BLUE}Open Ports:${NC}"
    ss -tlnp | grep -E ":(22|32400|8989|7878|9696)" || echo "No arr-stack ports open"
    
    # Show resource usage
    echo -e "\n${BLUE}Resource Usage:${NC}"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
}

show_urls() {
    local ip=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${GREEN}Access URLs:${NC}"
    echo "=================================="
    echo "🎬 Plex Media Server: http://$ip:32400/web"
    
    if systemctl is-active --quiet sonarr 2>/dev/null; then
        echo "📺 Sonarr (TV): http://$ip:8989"
    fi
    
    if systemctl is-active --quiet radarr 2>/dev/null; then
        echo "🎥 Radarr (Movies): http://$ip:7878"
    fi
    
    if systemctl is-active --quiet prowlarr 2>/dev/null; then
        echo "🔍 Prowlarr (Indexers): http://$ip:9696"
    fi
}

show_help() {
    cat << EOF
Host-based *Arr Stack Deployment Script

Usage: $0 [COMMAND] [HOST_NAME]

Commands:
    deploy [host]   Deploy configuration to specified host (default: arr-lxc)
    build [host]    Build configuration without deploying
    status [host]   Show system and service status
    check [host]    Check and restart failed services
    update          Update flake inputs
    urls            Show service access URLs
    help            Show this help message

Examples:
    $0 deploy                    # Deploy to default host (arr-lxc)
    $0 deploy my-arr-server      # Deploy to specific host
    $0 status arr-lxc            # Check status of arr-lxc
    $0 build arr-lxc             # Build without deploying

Host Configuration:
    The host configuration should be in your flake.nix:
    nixosConfigurations.\$HOST_NAME = nixpkgs.lib.nixosSystem { ... };

EOF
}

main() {
    case "${1:-deploy}" in
        deploy)
            HOST_NAME="${2:-$HOST_NAME}"
            check_host_config
            update_inputs
            deploy_config
            check_services
            show_status
            show_urls
            ;;
        build)
            HOST_NAME="${2:-$HOST_NAME}"
            check_host_config
            build_config
            ;;
        status)
            HOST_NAME="${2:-$HOST_NAME}"
            show_status
            show_urls
            ;;
        check)
            check_services
            ;;
        update)
            update_inputs
            ;;
        urls)
            show_urls
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
