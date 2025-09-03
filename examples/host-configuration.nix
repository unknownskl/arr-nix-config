# Example host configuration for the LXC container
# This would be in your host repo at hosts/arr-lxc/configuration.nix
{ config, lib, pkgs, ... }:

{
  # System configuration specific to this host
  system.stateVersion = "24.05";

  # Host-specific networking (if any additional config needed)
  networking = {
    # The hostname is set by arr-stack module
    # Add any additional network configuration here
    interfaces.eth0.useDHCP = true;
  };

  # Additional packages specific to this host
  environment.systemPackages = with pkgs; [
    # Add any additional packages you need
    rsync
    screen
  ];

  # Host-specific services
  services = {
    # The arr-stack services are configured via the module
    # Add any additional services here
    
    # Example: Enable automatic updates
    automatic-updates = {
      enable = true;
      channel = "nixos-24.05";
    };
  };

  # Additional users (beyond the 'media' user from arr-stack)
  users.users.admin = {
    isNormalUser = true;
    description = "Admin User";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = config.services.arr-stack.sshKeys;
  };

  # Host-specific security settings
  security = {
    # Additional sudo rules if needed
    sudo.extraRules = [
      {
        users = [ "admin" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
