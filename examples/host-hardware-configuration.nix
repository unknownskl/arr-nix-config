# Example hardware configuration for LXC container
# This would be in your host repo at hosts/arr-lxc/hardware-configuration.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # LXC container configuration
  boot.isContainer = true;

  # File systems for LXC
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # No swap devices in LXC typically
  swapDevices = [ ];

  # Networking interface
  networking.useDHCP = lib.mkDefault true;

  # Container-specific settings
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  
  # Disable hardware-specific features not needed in containers
  hardware = {
    enableAllFirmware = lib.mkDefault false;
    cpu.intel.updateMicrocode = lib.mkDefault false;
    cpu.amd.updateMicrocode = lib.mkDefault false;
  };
}
