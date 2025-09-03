# Prowlarr (Indexer management) configuration using Podman
{ config, pkgs, lib, ... }:

{
  config = lib.mkIf config.services.arr-stack.prowlarr.enable {
    # Create prowlarr directories
    systemd.tmpfiles.rules = [
      "d /var/lib/prowlarr 0755 media media -"
      "d /var/lib/prowlarr/config 0755 media media -"
    ];

    # Prowlarr container service
    systemd.services.prowlarr = {
      description = "Prowlarr Indexer Manager";
      after = [ "network.target" "podman.service" ];
      wants = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "forking";
        User = "media";
      Group = "media";
      ExecStartPre = [
        "${pkgs.podman}/bin/podman pull docker.io/linuxserver/prowlarr:latest"
        "-${pkgs.podman}/bin/podman stop prowlarr"
        "-${pkgs.podman}/bin/podman rm prowlarr"
      ];
      
      ExecStart = ''
        ${pkgs.podman}/bin/podman run -d \
          --name prowlarr \
          --restart unless-stopped \
          -p 9696:9696 \
          -e PUID=1000 \
          -e PGID=1000 \
          -e TZ=UTC \
          -v /var/lib/prowlarr/config:/config:Z \
          --memory=256m \
          --memory-swap=512m \
          --cpus=0.5 \
          docker.io/linuxserver/prowlarr:latest
      '';
      
      ExecStop = "${pkgs.podman}/bin/podman stop prowlarr";
      ExecStopPost = "${pkgs.podman}/bin/podman rm prowlarr";
      
      Restart = "always";
      RestartSec = "10s";
    };
  };

    # Firewall for Prowlarr
    networking.firewall.allowedTCPPorts = [ 9696 ];
  };
}
