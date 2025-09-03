# Radarr (Movie management) configuration using Podman
{ config, pkgs, lib, ... }:

{
  # Create radarr directories
  systemd.tmpfiles.rules = [
    "d /var/lib/radarr 0755 media media -"
    "d /var/lib/radarr/config 0755 media media -"
    "d /downloads/movies 0755 media media -"
  ];

  # Radarr container service
  systemd.services.radarr = {
    description = "Radarr Movie Manager";
    after = [ "network.target" "podman.service" ];
    wants = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "forking";
      User = "media";
      Group = "media";
      ExecStartPre = [
        "${pkgs.podman}/bin/podman pull docker.io/linuxserver/radarr:latest"
        "-${pkgs.podman}/bin/podman stop radarr"
        "-${pkgs.podman}/bin/podman rm radarr"
      ];
      
      ExecStart = ''
        ${pkgs.podman}/bin/podman run -d \
          --name radarr \
          --restart unless-stopped \
          -p 7878:7878 \
          -e PUID=1000 \
          -e PGID=1000 \
          -e TZ=UTC \
          -v /var/lib/radarr/config:/config:Z \
          -v /media/movies:/movies:Z \
          -v /downloads:/downloads:Z \
          --memory=512m \
          --memory-swap=1g \
          --cpus=1.0 \
          docker.io/linuxserver/radarr:latest
      '';
      
      ExecStop = "${pkgs.podman}/bin/podman stop radarr";
      ExecStopPost = "${pkgs.podman}/bin/podman rm radarr";
      
      Restart = "always";
      RestartSec = "10s";
    };
  };

  # Firewall for Radarr
  networking.firewall.allowedTCPPorts = [ 7878 ];
}
