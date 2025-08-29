# *Arr configuration for NixOS

## Install

### 1. Download nixos tarball

### 2. Create a new container

This needs to be done via the shell of Proxmox itself. Using the UI will have some flaws

    pct create "<ct id>" \
        --arch amd64 \
        "local-lvm:vztmpl/nixos-2024-10-25-system-x86_64-linux.tar.xz" \
        --ostype unmanaged \
        --description nixos \
        --hostname "thermic" \
        --net0 name=eth0,bridge=vmbr0,ip=dhcp,firewall=1 \
        --storage "local-lvm" \
        --memory "2048" \
        --rootfs local-lvm:10 \
        --unprivileged 1 \
        --features nesting=1 \
        --cmode console \
        --onboot 1 \
        --start 1

Example:

    pct create "225" \
        --arch amd64 \
        "ssd-drive:vztmpl/nixos-system-x86_64-linux.tar.xz" \
        --ostype unmanaged \
        --description nixarr \
        --hostname "nixarr" \
        --net0 name=eth0,hwaddr=BC:24:11:D3:B5:28,bridge=vmbr0,tag=202,firewall=1,ip6=dhcp,ip=dhcp \
        --storage "ssd-drive" \
        --memory "2048" \
        --rootfs ssd-drive:30 \
        --unprivileged 1 \
        --features nesting=1 \
        --cmode console \
        --onboot 1 \
        --start 1

### 3. Enable console access

To get console access working, follow the steps here: https://nixos.wiki/wiki/Proxmox_Linux_Container

### 4. Install flake

sudo nixos-rebuild switch --flake github:unknownskl/arr-nix-config#nixarr --no-write-lock-file