# *Arr Stack NixOS Configuration for Proxmox LXC

A modular NixOS configuration for running the *arr stack (Plex, Sonarr, Radarr, Prowlarr) in a Proxmox LXC container using rootless Podman containers. Optimized for performance and bare-metal efficiency.

## 🚀 Features

- **Modular Design**: Each service is configured in its own module
- **Rootless Containers**: Uses Podman for better security
- **Performance Optimized**: Tuned for LXC and bare-metal performance
- **Automated Deployment**: Simple script-based deployment
- **Health Monitoring**: Built-in health checks and backups
- **Resource Limits**: Proper memory and CPU constraints

## 📋 Services Included

- **Plex Media Server** (Port 32400) - Media streaming
- **Sonarr** (Port 8989) - TV show management (optional)
- **Radarr** (Port 7878) - Movie management (optional)
- **Prowlarr** (Port 9696) - Indexer management (optional)

## 🛠 Installation

### 1. Download NixOS LXC Template

Download the latest NixOS LXC template from the official releases:
```bash
wget https://github.com/NixOS/nixpkgs/releases/download/24.05/nixos-system-x86_64-linux.tar.xz
```

### 2. Create Proxmox LXC Container

Create the container using the Proxmox shell (not the UI):

```bash
pct create 225 \
    --arch amd64 \
    "local-lvm:vztmpl/nixos-system-x86_64-linux.tar.xz" \
    --ostype unmanaged \
    --description "NixOS *Arr Stack" \
    --hostname "arr-server" \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp,firewall=1 \
    --storage "local-lvm" \
    --memory "4096" \
    --rootfs local-lvm:50 \
    --unprivileged 1 \
    --features nesting=1 \
    --cmode console \
    --onboot 1 \
    --start 1
```

**Important Container Settings:**
- `--memory 4096`: 4GB RAM minimum (Plex transcoding needs memory)
- `--rootfs local-lvm:50`: 50GB storage minimum
- `--features nesting=1`: Required for containers within LXC
- `--unprivileged 1`: Use unprivileged container for security

### 3. Enable Console Access

Follow the [NixOS Wiki guide](https://nixos.wiki/wiki/Proxmox_Linux_Container) to enable console access:

1. Enter the container: `pct enter 225`
2. Edit `/etc/systemd/system/console-getty.service`:
   ```bash
   systemctl edit --full console-getty.service
   ```
3. Change `ExecStart` line to:
   ```
   ExecStart=-/sbin/agetty --noclear --keep-baud console 115200,38400,9600 $TERM
   ```

### 4. Deploy the Configuration

1. **Clone this repository:**
   ```bash
   git clone <your-repo-url> /etc/nixos/arr-config
   cd /etc/nixos/arr-config
   ```

2. **Customize the configuration:**
   - Edit `configuration.nix` to add your SSH keys
   - Adjust timezone in `modules/base.nix`
   - Modify resource limits in service modules if needed

3. **Deploy using the script:**
   ```bash
   ./deploy.sh deploy
   ```

   Or manually:
   ```bash
   sudo nixos-rebuild switch --flake .#arr-server
   ```

## 🔧 Configuration

### Adding SSH Keys

Edit `configuration.nix` and add your SSH public keys:

```nix
users.users.media = {
  # ... existing config ...
  openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2E... your-key@your-host"
  ];
};
```

### Enabling Additional Services

Uncomment the desired services in `configuration.nix`:

```nix
imports = [
  ./hardware-configuration.nix
  ./modules/base.nix
  ./modules/podman.nix
  ./modules/plex.nix
  ./modules/sonarr.nix    # Uncomment to enable
  ./modules/radarr.nix    # Uncomment to enable
  ./modules/prowlarr.nix  # Uncomment to enable
];
```

### Directory Structure

The configuration creates the following directories:
```
/var/lib/plex/          # Plex configuration and transcoding
/media/                 # Media library
├── movies/            # Movie files
├── tv/                # TV show files
└── music/             # Music files
/downloads/            # Download directory for *arr apps
```

## 🎯 Usage

### Management Commands

```bash
# Deploy configuration
./deploy.sh deploy

# Check service status
./deploy.sh status

# Check and restart failed services
./deploy.sh check

# Create configuration backup
./deploy.sh backup
```

### Service Management

```bash
# Check container status
sudo -u media podman ps

# View service logs
journalctl -u plex -f

# Restart a service
sudo systemctl restart plex

# Stop all containers
sudo -u media podman stop $(sudo -u media podman ps -q)
```

### Accessing Services

- **Plex**: `http://your-server-ip:32400/web`
- **Sonarr**: `http://your-server-ip:8989`
- **Radarr**: `http://your-server-ip:7878`
- **Prowlarr**: `http://your-server-ip:9696`

## 📊 Monitoring

### Container Health

The configuration includes automatic health checks:
- Plex health check runs every 5 minutes
- Failed containers are automatically restarted
- Daily configuration backups

### Resource Usage

Check resource usage:
```bash
# Container resources
sudo -u media podman stats

# System resources
htop
free -h
df -h
```

## 🔧 Troubleshooting

### Container Issues

```bash
# Check container logs
sudo -u media podman logs plex

# Restart container
sudo systemctl restart plex

# Rebuild container from scratch
sudo systemctl stop plex
sudo -u media podman rm plex
sudo systemctl start plex
```

### Permission Issues

```bash
# Fix media directory permissions
sudo chown -R media:media /media /var/lib/plex /downloads

# Check user namespace mapping
cat /etc/subuid
cat /etc/subgid
```

### Network Issues

```bash
# Check firewall
sudo iptables -L
sudo systemctl status firewall

# Test container networking
sudo -u media podman run --rm -it alpine:latest ping google.com
```

## 🚀 Performance Tuning

### For Plex Transcoding

1. **Increase memory limits** in `modules/plex.nix`:
   ```nix
   --memory=4g \
   --memory-swap=8g \
   ```

2. **Add more CPU cores**:
   ```nix
   --cpus=4.0 \
   ```

3. **Enable hardware transcoding** (if supported):
   Add device mappings for GPU access in the container configuration.

### For Download Performance

1. **Increase network buffers** (already configured in `modules/base.nix`)
2. **Use SSD storage** for the container root filesystem
3. **Separate downloads and media** on different storage if possible

## 🔄 Updates

### Update NixOS

```bash
# Update flake inputs
nix flake update

# Apply updates
./deploy.sh deploy
```

### Update Container Images

Container images are automatically pulled on service restart. To force update:

```bash
sudo systemctl restart plex sonarr radarr prowlarr
```

## 🗂 File Structure

```
.
├── configuration.nix           # Main NixOS configuration
├── hardware-configuration.nix  # Hardware/LXC specific config
├── flake.nix                   # Nix flake definition
├── flake.lock                  # Flake input locks
├── deploy.sh                   # Deployment script
├── docker-compose.yml          # Testing alternative
└── modules/                    # Service modules
    ├── base.nix               # Base system configuration
    ├── podman.nix             # Container runtime
    ├── plex.nix               # Plex Media Server
    ├── sonarr.nix             # TV show management
    ├── radarr.nix             # Movie management
    └── prowlarr.nix           # Indexer management
```

## 📝 Notes

- **Performance**: This configuration is optimized for bare-metal performance in LXC
- **Security**: Uses rootless containers and unprivileged LXC
- **Maintenance**: Includes automatic cleanup and backup scripts
- **Scalability**: Easy to add new services by creating additional modules

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

sudo nixos-rebuild switch --flake github:unknownskl/arr-nix-config#nixarr --no-write-lock-file









## Handy commands

Update flake lockfile:
    nix flake update --flake . --extra-experimental-features nix-command --extra-experimental-features flakes

