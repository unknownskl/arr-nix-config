{
  description = "*Arr stack NixOS configuration for Proxmox LXC";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable }: {
    # NixOS module that can be imported by host configurations
    nixosModules.arr-stack = { config, lib, pkgs, ... }: {
      imports = [
        ./modules/base.nix
        ./modules/podman.nix
        ./modules/plex.nix
        ./modules/sonarr.nix
        ./modules/radarr.nix
        ./modules/prowlarr.nix
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
        
        # Service-specific options
        sonarr.enable = lib.mkEnableOption "Enable Sonarr";
        radarr.enable = lib.mkEnableOption "Enable Radarr";
        prowlarr.enable = lib.mkEnableOption "Enable Prowlarr";
        
        # Media directories
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

      config = lib.mkIf config.services.arr-stack.enable {
        # System configuration
        system.stateVersion = lib.mkDefault "24.05";
        
        # Allow unfree packages (needed for Plex)
        nixpkgs.config.allowUnfree = true;
        
        # Network configuration for LXC
        networking = {
          hostName = config.services.arr-stack.hostname;
          networkmanager.enable = false; # Disable for LXC
          useDHCP = true;
          firewall = {
            enable = true;
            allowedTCPPorts = [ 
              22    # SSH
              32400 # Plex
              # Other service ports are handled by their respective modules
            ];
          };
        };

        # User configuration with SSH keys from options
        users.users.media = {
          isNormalUser = true;
          description = "Media Services User";
          extraGroups = [ "wheel" "podman" ];
          openssh.authorizedKeys.keys = config.services.arr-stack.sshKeys;
        };

        # Enable SSH for remote management
        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            PermitRootLogin = "no";
          };
        };

        # Set timezone
        time.timeZone = config.services.arr-stack.timezone;
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
