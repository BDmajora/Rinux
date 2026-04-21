#!/bin/bash
set -e

# --- 1. System Prep ---
echo "--- 1. Updating Debian 13 & Installing Base Tools ---"
sudo apt update
sudo apt install -y curl git build-essential xdg-utils

# --- 2. Robust Nix Check ---
# Check if nix is in PATH or if the installation directory exists
NIX_PROFILE="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"

if command -v nix &> /dev/null; then
    echo "--- 2. Nix is already in PATH. Skipping installation. ---"
elif [ -e "$NIX_PROFILE" ]; then
    echo "--- 2. Nix is installed but not in PATH. Sourcing now... ---"
    . "$NIX_PROFILE"
else
    echo "--- 2. Installing Nix (Daemon Mode) ---"
    # Handling the collision case: if an old failed install left backup files
    if [ -f "/etc/bash.bashrc.backup-before-nix" ]; then
        echo "Warning: Old Nix backup found. Cleaning up to allow fresh install..."
        sudo rm -f /etc/bash.bashrc.backup-before-nix
    fi
    
    curl -L https://nixos.org/nix/install | sh -s -- --daemon
    . "$NIX_PROFILE"
fi

# Enable Flakes
mkdir -p ~/.config/nix
if ! grep -q "experimental-features = nix-command flakes" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
fi

# --- 3. Build River ---
echo "--- 3. Building River Compositor ---"
nix develop --extra-experimental-features "nix-command flakes" --command bash -c "
    if [ ! -d 'river' ]; then
        git clone --recursive https://github.com/riverwm/river
    fi
    cd river
    
    # CRITICAL: Clean the cache that caused the Wayland header errors
    rm -rf .zig-cache zig-out
    
    zig build -Doptimize=ReleaseSafe
    
    echo 'Installing River binaries...'
    sudo cp zig-out/bin/river /usr/local/bin/
    sudo cp zig-out/bin/riverctl /usr/local/bin/
"

# --- 4. Scaffolding ---
echo "--- 4. Setting up Rinux Project Structure ---"
mkdir -p protocol src include
if [ ! -f "protocol/river-window-management-v1.xml" ]; then
    wget -q https://raw.githubusercontent.com/riverwm/river/master/protocol/river-window-management-v1.xml \
         -O protocol/river-window-management-v1.xml
fi

echo "--- SUCCESS: Rinux Workspace Ready ---"