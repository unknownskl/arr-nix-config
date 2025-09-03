# Example host flake.nix that uses the arr-stack module
{
  description = "My NixOS host configuration with *arr stack";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    
    # Import the arr-stack configuration
    arr-config = {
      url = "github:yourusername/arr-nix-config";
      # Or for local development:
      # url = "path:/path/to/arr-nix-config";
    };
  };

  outputs = { self, nixpkgs, arr-config }: {
    nixosConfigurations = {
      # Your LXC container configuration
      arr-lxc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Import the arr-stack module
          arr-config.nixosModules.arr-stack
          
          # Your host-specific configuration
          ./hosts/arr-lxc/configuration.nix
          
          # Hardware configuration for LXC
          ./hosts/arr-lxc/hardware-configuration.nix
          
          # Configure the arr-stack services
          {
            services.arr-stack = {
              enable = true;
              
              # Your specific configuration
              hostname = "my-arr-server";
              timezone = "America/New_York";  # Set your timezone
              
              # Your SSH keys (no need to commit these)
              sshKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIYourKeyHere user@hostname"
                "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... user@hostname"
              ];
              
              # Enable additional services
              sonarr.enable = true;
              radarr.enable = true;
              prowlarr.enable = true;
              
              # Custom media directories if needed
              mediaDirectories = {
                movies = "/media/movies";
                tv = "/media/tv-shows";
                downloads = "/downloads";
              };
            };
          }
        ];
      };

      # You can have other hosts too
      my-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/desktop/configuration.nix
          # arr-stack not enabled here
        ];
      };
    };
  };
}
