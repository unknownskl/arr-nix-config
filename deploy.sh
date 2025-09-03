#!/usr/bin/env bash

# NixOS *Arr Stack Deployment Script
# This script helps deploy and manage the *arr stack configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLAKE_PATH="."
HOSTNAME="arr-server"

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

check_requirements() {
    log "Checking requirements..."
    
    if ! command -v nixos-rebuild &> /dev/null; then
        error "nixos-rebuild not found. Are you running on NixOS?"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        error "git not found. Installing git..."
        nix-env -iA nixos.git
    fi
    
    success "Requirements check passed"
}

backup_existing() {
    log "Creating backup of existing configuration..."
    
    if [[ -f /etc/nixos/configuration.nix ]]; then
        sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup.$(date +%Y%m%d_%H%M%S)
        success "Backup created"
    else
        warn "No existing configuration found"
    fi
}

deploy() {
    log "Deploying NixOS configuration..."
    
    # Update flake inputs
    log "Updating flake inputs..."
    nix flake update
    
    # Build the configuration
    log "Building configuration..."
    sudo nixos-rebuild switch --flake "${FLAKE_PATH}#${HOSTNAME}"
    
    success "Deployment completed successfully!"
}

check_services() {
    log "Checking service status..."
    
    services=("plex")
    
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
    log "System Status:"
    echo "================="
    
    # Show running containers
    echo -e "\n${BLUE}Running Containers:${NC}"
    sudo -u media podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Show service status
    echo -e "\n${BLUE}Service Status:${NC}"
    systemctl status plex --no-pager -l || true
    
    # Show open ports
    echo -e "\n${BLUE}Open Ports:${NC}"
    ss -tlnp | grep -E ":(32400|8989|7878|9696)" || echo "No media services ports open"
    
    # Show resource usage
    echo -e "\n${BLUE}Resource Usage:${NC}"
    free -h
    df -h / | tail -1
}

show_help() {
    cat << EOF
NixOS *Arr Stack Management Script

Usage: $0 [COMMAND]

Commands:
    deploy      Deploy the configuration to the system
    status      Show system and service status
    backup      Create backup of current configuration
    check       Check service status and restart if needed
    help        Show this help message

Examples:
    $0 deploy   # Deploy the full stack
    $0 status   # Check current status
    $0 check    # Verify services are running

EOF
}

main() {
    case "${1:-help}" in
        deploy)
            check_requirements
            backup_existing
            deploy
            check_services
            show_status
            ;;
        status)
            show_status
            ;;
        backup)
            backup_existing
            ;;
        check)
            check_services
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
