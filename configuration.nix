# Main NixOS configuration for *arr stack server
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/base.nix
    ./modules/podman.nix
    ./modules/plex.nix
    # Future arr services
    # ./modules/sonarr.nix
    # ./modules/radarr.nix
    # ./modules/prowlarr.nix
    # ./modules/bazarr.nix
  ];

  # System configuration
  system.stateVersion = "24.05"; # Update to your NixOS version

  # Network configuration for LXC
  networking = {
    hostName = "arr-server";
    networkmanager.enable = false; # Disable for LXC
    useDHCP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 
        22    # SSH
        32400 # Plex
        # Add other service ports as needed
      ];
    };
  };

  # User configuration
  users.users.media = {
    isNormalUser = true;
    description = "Media Services User";
    extraGroups = [ "wheel" "podman" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
      # "ssh-rsa AAAAB3NzaC1yc2E... your-key@your-host"
    ];
  };

  # Enable SSH for remote management
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
