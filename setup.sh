#!/bin/bash
set -e

echo "--- 1. Installing Debian System Dependencies ---"
sudo apt update
sudo apt install -y build-essential gcc g++ libwayland-dev libwayland-bin \
    wayland-protocols pkg-config libwlroots-0.18-dev libxkbcommon-dev \
    libpixman-1-dev libinput-dev libudev-dev libgbm-dev wget git

# --- 2. Getting Zig (Temporary tool for building the compositor) ---
if [ -d "zig-linux-x86_64-0.11.0" ]; then
    rm -rf zig-linux-x86_64-0.11.0*
fi

if [ ! -f "/usr/local/bin/river" ]; then
    if [ ! -d "zig-linux-x86_64-0.13.0" ]; then
        echo "--- Downloading Zig Toolchain (0.13.0) ---"
        wget https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz
        tar -xf zig-linux-x86_64-0.13.0.tar.xz
    fi
    export PATH=$PATH:$(pwd)/zig-linux-x86_64-0.13.0

    # --- 3. Building River (The Host Compositor) ---
    if [ ! -d "river" ]; then
        echo "--- Cloning and Building River ---"
        git clone https://codeberg.org/river/river
        cd river
        zig build -Doptimize=ReleaseSafe
        sudo cp zig-out/bin/river /usr/local/bin/
        cd ..
    fi
    
    # Optional: Clean up Zig and the river folder to save space on the VM
    # rm -rf zig-linux-x86_64-0.13.0* river
fi

# --- 4. Setting up Rinux-WM ---
echo "--- Preparing Rinux-WM ---"
mkdir -p protocol src include

# Fetch the specific protocol file your C++ code needs
wget https://codeberg.org/river/river/raw/branch/master/protocol/river-window-management-v1.xml \
     -O protocol/river-window-management-v1.xml

# Make sure your existing build.sh is executable and run it
if [ -f build.sh ]; then
    chmod +x build.sh
    echo "--- Running Build ---"
    ./build.sh
fi

echo "--- SUCCESS ---"
echo "To test: Type 'river' to start the compositor,"
echo "then run './rinux-wm' from a terminal inside River."