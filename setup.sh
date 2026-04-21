#!/bin/bash
set -e

# --- 1. System Prep (Host Level) ---
echo "--- 1. Updating Debian 13 & Installing Base Tools ---"
sudo apt update
sudo apt install -y curl git build-essential xdg-utils

# --- 2. Nix Installation Engine ---
if ! command -v nix &> /dev/null; then
    echo "--- 2. Installing Nix (Daemon Mode) ---"
    curl -L https://nixos.org/nix/install | sh -s -- --daemon
    # Load Nix immediately for this session
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
fi

# Enable Flakes if they aren't already
mkdir -p ~/.config/nix
if ! grep -q "experimental-features = nix-command flakes" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
fi

# --- 3. Build River using the Flake ---
echo "--- 3. Building River Compositor ---"
# We use 'nix develop' to run the build inside the shell we defined in flake.nix
nix develop --command bash -c "
    if [ ! -d 'river' ]; then
        git clone --recursive https://github.com/riverwm/river
    fi
    cd river
    zig build -Doptimize=ReleaseSafe
    
    echo 'Installing River binaries to /usr/local/bin...'
    sudo cp zig-out/bin/river /usr/local/bin/
    sudo cp zig-out/bin/riverctl /usr/local/bin/
"

# --- 4. Project Scaffolding ---
echo "--- 4. Setting up Rinux Project Structure ---"
mkdir -p protocol src include

if [ ! -f "protocol/river-window-management-v1.xml" ]; then
    wget -q https://raw.githubusercontent.com/riverwm/river/master/protocol/river-window-management-v1.xml \
         -O protocol/river-window-management-v1.xml
fi

echo "--- SUCCESS: Rinux Workspace Ready ---"
echo "To build your WM, simply run: 'nix develop --command ./build.sh'"