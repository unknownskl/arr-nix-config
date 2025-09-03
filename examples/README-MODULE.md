# Using *Arr Stack as a NixOS Module

This guide shows how to use the *arr stack configuration as a module in your host NixOS configuration, allowing you to keep secrets and host-specific configuration separate from the shared arr-stack code.

## 🎯 Benefits of the Modular Approach

- ✅ **Separation of Concerns**: Secrets stay in your private host config
- ✅ **Reusability**: Use the same arr-stack across multiple hosts
- ✅ **Flexibility**: Enable/disable services per host
- ✅ **Updates**: Easy to update the arr-stack module independently
- ✅ **Security**: SSH keys and sensitive config never committed to public repos

## 📁 Directory Structure

Your host configuration repository should look like this:

```
my-nixos-config/
├── flake.nix                           # Your main flake
├── hosts/
│   ├── arr-lxc/
│   │   ├── configuration.nix           # Host-specific config
│   │   └── hardware-configuration.nix  # Hardware config
│   └── desktop/
│       ├── configuration.nix
│       └── hardware-configuration.nix
└── scripts/
    └── deploy.sh                       # Deployment script
```

## 🚀 Quick Setup

### 1. Create Your Host Flake

Create a `flake.nix` in your host configuration repository:

```nix
{
  description = "My NixOS configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    
    # Import the arr-stack module
    arr-config = {
      url = "github:yourusername/arr-nix-config";
      # For local development:
      # url = "path:/path/to/arr-nix-config";
    };
  };

  outputs = { self, nixpkgs, arr-config }: {
    nixosConfigurations = {
      arr-lxc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Import the arr-stack module
          arr-config.nixosModules.arr-stack
          
          # Your configurations
          ./hosts/arr-lxc/hardware-configuration.nix
          ./hosts/arr-lxc/configuration.nix
          
          # Configure arr-stack with your settings
          {
            services.arr-stack = {
              enable = true;
              hostname = "my-arr-server";
              timezone = "America/New_York";
              
              # Your SSH keys (safe to commit since it's your private repo)
              sshKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... user@host"
              ];
              
              # Enable services you want
              sonarr.enable = true;
              radarr.enable = true;
              prowlarr.enable = true;
            };
          }
        ];
      };
    };
  };
}
```

### 2. Create Host Configuration

Create `hosts/arr-lxc/configuration.nix`:

```nix
{ config, lib, pkgs, ... }:

{
  system.stateVersion = "24.05";

  # Additional packages for this host
  environment.systemPackages = with pkgs; [
    rsync
    screen
  ];

  # Additional users if needed
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = config.services.arr-stack.sshKeys;
  };
}
```

### 3. Create Hardware Configuration

Use the provided example or generate one:

```bash
nixos-generate-config --show-hardware-config > hosts/arr-lxc/hardware-configuration.nix
```

### 4. Deploy

```bash
# Copy the deployment script
cp /path/to/arr-nix-config/examples/host-deploy.sh scripts/deploy.sh
chmod +x scripts/deploy.sh

# Deploy your configuration
./scripts/deploy.sh deploy arr-lxc
```

## ⚙️ Configuration Options

The arr-stack module provides these configuration options:

### Basic Options

```nix
services.arr-stack = {
  enable = true;                    # Enable the arr-stack
  hostname = "my-server";           # Server hostname
  timezone = "America/New_York";    # System timezone
  sshKeys = [ "ssh-ed25519..." ];   # SSH public keys
};
```

### Service Options

```nix
services.arr-stack = {
  # Enable specific services
  sonarr.enable = true;     # TV show management
  radarr.enable = true;     # Movie management  
  prowlarr.enable = true;   # Indexer management
};
```

### Directory Options

```nix
services.arr-stack = {
  mediaDirectories = {
    movies = "/media/movies";       # Movies directory
    tv = "/media/tv-shows";         # TV shows directory
    downloads = "/downloads";       # Downloads directory
  };
};
```

## 🔧 Development Workflow

### Local Development

For local development of the arr-stack module:

```nix
# In your host flake.nix
arr-config = {
  url = "path:/path/to/local/arr-nix-config";
};
```

### Testing Changes

```bash
# Test the module configuration
nix flake check

# Build without deploying
./scripts/deploy.sh build arr-lxc

# Deploy changes
./scripts/deploy.sh deploy arr-lxc
```

### Updating the Module

```bash
# Update to latest version
nix flake update

# Deploy updates
./scripts/deploy.sh deploy arr-lxc
```

## 🎛️ Advanced Configuration

### Multiple Hosts

You can configure different arr-stack setups for different hosts:

```nix
nixosConfigurations = {
  # Production server with all services
  arr-prod = nixpkgs.lib.nixosSystem {
    modules = [
      arr-config.nixosModules.arr-stack
      {
        services.arr-stack = {
          enable = true;
          sonarr.enable = true;
          radarr.enable = true;
          prowlarr.enable = true;
        };
      }
    ];
  };
  
  # Development server with just Plex
  arr-dev = nixpkgs.lib.nixosSystem {
    modules = [
      arr-config.nixosModules.arr-stack
      {
        services.arr-stack = {
          enable = true;
          # Only Plex enabled by default
        };
      }
    ];
  };
};
```

### Override Module Configuration

You can override specific parts of the module:

```nix
{
  services.arr-stack.enable = true;
  
  # Override firewall settings
  networking.firewall.allowedTCPPorts = [ 22 32400 8080 ];
  
  # Add additional packages
  environment.systemPackages = with pkgs; [ 
    htop 
    neovim 
  ];
  
  # Override user configuration
  users.users.media.shell = pkgs.zsh;
}
```

## 🔍 Troubleshooting

### Module Not Found

```bash
# Check if the module is available
nix flake show github:yourusername/arr-nix-config

# Verify the module path
nix eval .#nixosModules.arr-stack --json
```

### Configuration Errors

```bash
# Check flake syntax
nix flake check

# Build configuration to see errors
nix build .#nixosConfigurations.arr-lxc.config.system.build.toplevel
```

### Service Issues

```bash
# Check service status
./scripts/deploy.sh status arr-lxc

# Check specific service
systemctl status plex

# View logs
journalctl -u plex -f
```

## 📚 Examples

See the `examples/` directory for:
- `host-flake.nix` - Complete host flake example
- `host-configuration.nix` - Host-specific configuration
- `host-hardware-configuration.nix` - Hardware configuration for LXC
- `host-deploy.sh` - Deployment script for host configs

## 🤝 Contributing

This modular approach makes it easy to contribute back to the arr-stack:
1. Test changes in your host configuration
2. Submit PRs to the arr-stack repository
3. Update your host configuration to use the new version
