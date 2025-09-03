# Base system configuration
{ config, pkgs, lib, ... }:

{
  # Enable flakes
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # Essential tools
    git
    curl
    wget
    htop
    tree
    unzip
    nano
    vim
    
    # Container management
    podman-compose
    podman-tui
    
    # Monitoring and diagnostics
    iotop
    nethogs
    lsof
    tcpdump
  ];

  # Time zone and locale - now configured via options
  # time.timeZone is set in the main module based on services.arr-stack.timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable sudo without password for wheel group (for automation)
  security.sudo.wheelNeedsPassword = false;

  # Optimize for LXC container environment
  boot = {
    # LXC doesn't need a bootloader
    isContainer = true;
    
    # Kernel parameters for performance
    kernel.sysctl = {
      # Network optimizations
      "net.core.rmem_max" = 268435456;
      "net.core.wmem_max" = 268435456;
      "net.ipv4.tcp_rmem" = "4096 87380 268435456";
      "net.ipv4.tcp_wmem" = "4096 65536 268435456";
      
      # File system optimizations
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;
      "vm.swappiness" = 10;
    };
  };

  # Systemd optimizations for containers
  systemd = {
    # Reduce journal size to save space
    extraConfig = ''
      DefaultTimeoutStopSec=10s
    '';
    
    services = {
      # Disable unnecessary services for containers
      systemd-udev-trigger.enable = false;
      systemd-udevd.enable = false;
    };

    services."sys-kernel-debug.mount".enable = false;

    tmpfiles = {
        rules = [
          "d /sys/kernel/debug 0555 root root -"
        ];
    };
  };

  # Performance and resource management
  services = {
    # Enable periodic TRIM for SSDs
    fstrim.enable = true;
    
    # Disable unnecessary services for container environment
    udisks2.enable = false;
    
    # Enable logrotate to manage log files
    logrotate.enable = true;
  };
}
