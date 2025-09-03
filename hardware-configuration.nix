# Hardware configuration for LXC container
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # LXC container doesn't need boot configuration
  boot.isContainer = true;

  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # No swap needed in LXC typically
  swapDevices = [ ];

  # Enable all firmware (harmless in container)
  hardware.enableAllFirmware = lib.mkDefault false;

  # Networking interface
  networking.useDHCP = lib.mkDefault true;

  # Disable unnecessary hardware detection
  hardware.cpu.intel.updateMicrocode = lib.mkDefault false;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault false;

  # Container-specific optimizations
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
