#!/usr/bin/env bash

# Quick setup script for testing the *arr stack configuration
# This script prepares the environment for testing

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Create directory structure for testing
create_directories() {
    log "Creating directory structure..."
    
    mkdir -p {data,media,downloads}/{plex,sonarr,radarr,prowlarr}
    mkdir -p media/{movies,tv,music}
    mkdir -p downloads/{movies,tv}
    mkdir -p data/plex/{config,transcode}
    
    success "Directory structure created"
}

# Set proper permissions
set_permissions() {
    log "Setting permissions..."
    
    # Get current user ID
    CURRENT_UID=$(id -u)
    CURRENT_GID=$(id -g)
    
    # Set ownership
    sudo chown -R $CURRENT_UID:$CURRENT_GID data/ media/ downloads/ 2>/dev/null || {
        warn "Could not set ownership (normal if not running as root)"
    }
    
    success "Permissions configured"
}

# Check requirements
check_requirements() {
    log "Checking requirements..."
    
    # Check if we're on NixOS
    if [[ -f /etc/NIXOS ]]; then
        success "Running on NixOS"
    else
        warn "Not running on NixOS - this configuration is designed for NixOS"
    fi
    
    # Check for required commands
    local missing=()
    
    for cmd in git nix; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Missing required commands: ${missing[*]}"
        log "Install them with: nix-env -iA nixos.git"
    else
        success "All requirements met"
    fi
}

# Test flake configuration
test_flake() {
    log "Testing flake configuration..."
    
    if nix flake check --no-build 2>/dev/null; then
        success "Flake configuration is valid"
    else
        warn "Flake configuration has issues, running detailed check..."
        nix flake check
    fi
}

# Show next steps
show_next_steps() {
    cat << EOF

${GREEN}Setup Complete!${NC}

${BLUE}Directory Structure:${NC}
$(tree -L 2 2>/dev/null || find . -type d -name ".*" -prune -o -type d -print | head -20)

${BLUE}Next Steps:${NC}

1. ${YELLOW}Customize Configuration:${NC}
   - Edit configuration.nix to add your SSH keys
   - Adjust timezone in modules/base.nix
   - Review resource limits in service modules

2. ${YELLOW}Deploy Configuration:${NC}
   ./deploy.sh deploy

3. ${YELLOW}Test with Docker Compose (optional):${NC}
   docker-compose up -d plex

4. ${YELLOW}Access Services:${NC}
   - Plex: http://localhost:32400/web
   - Sonarr: http://localhost:8989
   - Radarr: http://localhost:7878
   - Prowlarr: http://localhost:9696

${BLUE}Management Commands:${NC}
   ./deploy.sh status  # Check service status
   ./deploy.sh check   # Verify and restart services
   ./deploy.sh backup  # Create configuration backup

EOF
}

main() {
    log "Starting *arr stack setup..."
    
    check_requirements
    create_directories
    set_permissions
    test_flake
    show_next_steps
    
    success "Setup completed successfully!"
}

main "$@"
