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
    
    # Load Nix immediately for the current session
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
fi

# Ensure Flakes are enabled in the Nix config
mkdir -p ~/.config/nix
if ! grep -q "experimental-features = nix-command flakes" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
fi

# --- 3. Build River using the Flake ---
echo "--- 3. Building River Compositor ---"
# We use 'nix develop' to run the build inside the environment defined in your flake.nix
nix develop --extra-experimental-features "nix-command flakes" --command bash -c "
    if [ ! -d 'river' ]; then
        git clone --recursive https://github.com/riverwm/river
    fi
    cd river
    
    # FIX: Remove the dirty host cache that caused the Wayland header errors
    echo 'Clearing old build cache to prevent header conflicts...'
    rm -rf .zig-cache zig-out
    
    echo 'Starting Zig build...'
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

# Generate the initial protocol headers so your IDE stops complaining immediately
echo "--- 5. Generating Protocol Headers ---"
nix develop --extra-experimental-features "nix-command flakes" --command bash -c "
    wayland-scanner client-header protocol/river-window-management-v1.xml src/river-window-management-v1-client-protocol.h
    wayland-scanner private-code protocol/river-window-management-v1.xml src/river-window-management-v1-client-protocol.c
"

echo "--- SUCCESS: Rinux Workspace Ready ---"
echo "To build your custom WM, run: nix develop --command ./build.sh"