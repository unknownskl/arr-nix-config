{
  description = "*Arr stack NixOS configuration for Proxmox LXC";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    # NixOS module that can be imported by host configurations
    nixosModules.arr-stack = { config, lib, pkgs, ... }: {
      imports = [
        # ./modules/base.nix
        # ./modules/podman.nix
        # ./modules/plex.nix
        # ./modules/sonarr.nix
        # ./modules/radarr.nix
        # ./modules/prowlarr.nix
      ];

      options.services.arr-stack = {
        enable = lib.mkEnableOption "Enable *arr stack services";
        
        sshKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "SSH public keys for the media user";
        };

        hostname = lib.mkOption {
          type = lib.types.str;
          default = "arr-server";
          description = "Hostname for the server";
        };
        
        timezone = lib.mkOption {
          type = lib.types.str;
          default = "UTC";
          description = "System timezone";
        };

        mediaDirectories = {
          movies = lib.mkOption {
            type = lib.types.str;
            default = "/media/movies";
            description = "Movies directory path";
          };
          tv = lib.mkOption {
            type = lib.types.str;
            default = "/media/tv";
            description = "TV shows directory path";
          };
          downloads = lib.mkOption {
            type = lib.types.str;
            default = "/downloads";
            description = "Downloads directory path";
          };
        };
      };

      # Standalone configuration for direct deployment (backward compatibility)
    nixosConfigurations.arr-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        self.nixosModules.arr-stack
        {
          services.arr-stack = {
            enable = true;
            # Default configuration - override in host
            sshKeys = [
              # Add your SSH public keys here when using standalone
            ];
          };
        }
      ];
    };

    # Development shell for testing and deployment
    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
        git
        nixos-rebuild
        podman
        podman-compose
      ];
      
      shellHook = ''
        echo "🚀 *Arr stack development environment"
        echo "📁 Available commands:"
        echo "  - nixos-rebuild switch --flake .#arr-server (deploy standalone)"
        echo "  - Import as module in your host configuration"
      '';
    };

    # Packages for easy access
    packages.x86_64-linux = {
      # Build the full system configuration
      arr-server = self.nixosConfigurations.arr-server.config.system.build.toplevel;
      default = self.packages.x86_64-linux.arr-server;
    };

  };
}