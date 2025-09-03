# Podman configuration for rootless containers
{ config, pkgs, lib, ... }:

{
  # Enable podman for rootless containers
  virtualisation.podman = {
    enable = true;
    
    # Required for rootless containers
    defaultNetwork.settings.dns_enabled = true;
    
    # Performance optimizations
    extraPackages = with pkgs; [
      # Required for podman-compose
      # python3Packages.podman-compose
      
      # Networking tools
      aardvark-dns
      netavark
      
      # Container runtime optimizations
      crun  # Faster than runc
      conmon
      shadow
    ];
  };

  # Enable container registry access
  virtualisation.containers = {
    enable = true;

    # OCI Runtime configuration
    oci-runtimes.crun = {
      enable = true;
      package = pkgs.crun;
    };
    
    # Registry configuration
    registries = {
      search = [ "docker.io" "quay.io" "ghcr.io" ];
      insecure = [ ];
      block = [ ];
    };
    
    # Storage configuration for performance
    storage.settings = {
      storage = {
        driver = "overlay";
        runroot = "/run/containers/storage";
        graphroot = "/var/lib/containers/storage";
        
        # Performance options
        options.overlay = {
          mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs";
          mountopt = "nodev,metacopy=on";
        };
      };
    };
    
    # Policy configuration
    policy = {
      default = [ { type = "insecureAcceptAnything"; } ];
      transports = {
        docker-daemon = {
          "" = [ { type = "insecureAcceptAnything"; } ];
        };
      };
    };


    
    # Container engine configuration
    containersConf.settings = {
      containers = {
        default_capabilities = [
          "CHOWN"
          "DAC_OVERRIDE" 
          "FOWNER"
          "FSETID"
          "KILL"
          "NET_BIND_SERVICE"
          "SETFCAP"
          "SETGID"
          "SETPCAP"
          "SETUID"
          "SYS_CHROOT"
        ];
      };
      engine = {
        # Set crun as default runtime
        runtime = "crun";
        # Add crun to runtimes list
        runtimes.crun = [ "${pkgs.crun}/bin/crun" ];
      };
    };
  };

  # Configure user namespaces for rootless containers
  users.users.media = {
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };

  # Systemd service for container health monitoring
  systemd.services.container-health-check = {
    description = "Monitor container health";
    serviceConfig = {
      Type = "oneshot";
      User = "media";
      ExecStart = "${pkgs.podman}/bin/podman system prune -f --volumes";
    };
    # Run weekly cleanup
    startAt = "weekly";
  };

  # Enable podman socket for API access (optional)
  systemd.user.services.podman = {
    enable = true;
    wantedBy = [ "default.target" ];
  };

  # Configure systemd to handle user lingering for media user
  # This allows user services to run even when user is not logged in
  system.activationScripts.enableLinger = ''
    ${pkgs.systemd}/bin/loginctl enable-linger media
  '';
}
