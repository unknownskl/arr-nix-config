# Sonarr (TV Show management) configuration using Podman
{ config, pkgs, lib, ... }:

{
  # Create sonarr directories
  systemd.tmpfiles.rules = [
    "d /var/lib/sonarr 0755 media media -"
    "d /var/lib/sonarr/config 0755 media media -"
    "d /downloads 0755 media media -"
    "d /downloads/tv 0755 media media -"
  ];

  # Sonarr container service
  systemd.services.sonarr = {
    description = "Sonarr TV Show Manager";
    after = [ "network.target" "podman.service" ];
    wants = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "forking";
      User = "media";
      Group = "media";
      ExecStartPre = [
        "${pkgs.podman}/bin/podman pull docker.io/linuxserver/sonarr:latest"
        "-${pkgs.podman}/bin/podman stop sonarr"
        "-${pkgs.podman}/bin/podman rm sonarr"
      ];
      
      ExecStart = ''
        ${pkgs.podman}/bin/podman run -d \
          --name sonarr \
          --restart unless-stopped \
          -p 8989:8989 \
          -e PUID=1000 \
          -e PGID=1000 \
          -e TZ=UTC \
          -v /var/lib/sonarr/config:/config:Z \
          -v /media/tv:/tv:Z \
          -v /downloads:/downloads:Z \
          --memory=512m \
          --memory-swap=1g \
          --cpus=1.0 \
          docker.io/linuxserver/sonarr:latest
      '';
      
      ExecStop = "${pkgs.podman}/bin/podman stop sonarr";
      ExecStopPost = "${pkgs.podman}/bin/podman rm sonarr";
      
      Restart = "always";
      RestartSec = "10s";
    };
  };

  # Firewall for Sonarr
  networking.firewall.allowedTCPPorts = [ 8989 ];
}
