# Plex Media Server configuration using Podman
{ config, pkgs, lib, ... }:

{
  # Create media directories and backup directory
  systemd.tmpfiles.rules = [
    "d /var/lib/plex 0755 media media -"
    "d /var/lib/plex/config 0755 media media -"
    "d /var/lib/plex/transcode 0755 media media -"
    "d /var/lib/plex/backups 0755 media media -"
    "d /media 0755 media media -"
    "d /media/movies 0755 media media -"
    "d /media/tv 0755 media media -"
    "d /media/music 0755 media media -"
  ];

  # Plex container service
  systemd.services.plex = {
    description = "Plex Media Server";
    after = [ "network.target" "podman.service" ];
    wants = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "forking";
      User = "media";
      Group = "media";
      # Ensure PATH includes shadow utilities
      Environment = [
        "PATH=/run/wrappers/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
      ];
      ExecStartPre = [
        # Pull the latest image
        "${pkgs.podman}/bin/podman pull docker.io/plexinc/pms-docker:latest"
        
        # Stop and remove existing container if it exists
        "-${pkgs.podman}/bin/podman stop plex"
        "-${pkgs.podman}/bin/podman rm plex"
      ];
      
      ExecStart = ''
        ${pkgs.podman}/bin/podman run -d \
          --name plex \
          --restart unless-stopped \
          --network host \
          --user $(id -u):$(id -g) \
          -e TZ=UTC \
          -e PLEX_CLAIM="" \
          -e ADVERTISE_IP="http://$(hostname -I | awk '{print $1}'):32400/" \
          -v /var/lib/plex/config:/config:Z \
          -v /var/lib/plex/transcode:/transcode:Z \
          -v /media:/data:ro \
          --security-opt label=disable \
          --memory=1g \
          --memory-swap=2g \
          --cpus=2.0 \
          docker.io/plexinc/pms-docker:latest
      '';
      
      ExecStop = "${pkgs.podman}/bin/podman stop plex";
      ExecStopPost = "${pkgs.podman}/bin/podman rm plex";
      
      # Restart policy
      Restart = "always";
      RestartSec = "10s";
      
      # Resource limits
      MemoryMax = "2G";
      CPUQuota = "200%";
    };
    
    # Environment for optimal performance
    environment = {
      PODMAN_USERNS = "keep-id";
    };
  };

  # Firewall configuration for Plex
  networking.firewall.allowedTCPPorts = [ 32400 ];
  
  # Optional: Allow Plex DLNA and discovery
  networking.firewall.allowedUDPPorts = [ 1900 5353 32410 32412 32413 32414 ];

  # Systemd service for Plex health monitoring
  systemd.services.plex-health-check = {
    description = "Check Plex container health";
    serviceConfig = {
      Type = "oneshot";
      User = "media";
      ExecStart = pkgs.writeScript "plex-health-check" ''
        #!/bin/bash
        if ! ${pkgs.podman}/bin/podman ps | grep -q plex; then
          echo "Plex container is not running, restarting..."
          systemctl restart plex
        fi
      '';
    };
    # Check every 5 minutes
    startAt = "*:0/5";
  };

  # Backup script for Plex configuration
  systemd.services.plex-backup = {
    description = "Backup Plex configuration";
    serviceConfig = {
      Type = "oneshot";
      User = "media";
      ExecStart = pkgs.writeScript "plex-backup" ''
        #!/bin/bash
        BACKUP_DIR="/var/lib/plex/backups"
        mkdir -p "$BACKUP_DIR"
        
        # Create timestamped backup
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        tar -czf "$BACKUP_DIR/plex_config_$TIMESTAMP.tar.gz" \
          -C /var/lib/plex/config .
        
        # Keep only last 7 backups
        ls -t "$BACKUP_DIR"/plex_config_*.tar.gz | tail -n +8 | xargs -r rm
      '';
    };
    # Run daily at 2 AM
    startAt = "02:00";
  };
}
