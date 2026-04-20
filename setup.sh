#!/bin/bash
set -e

echo "--- 1. Installing Debian System Dependencies ---"
sudo apt update
# RESTORED: Your original libwlroots-0.18-dev
sudo apt install -y build-essential gcc g++ libwayland-dev libwayland-bin \
    wayland-protocols pkg-config libwlroots-0.18-dev libxkbcommon-dev \
    libpixman-1-dev libinput-dev libudev-dev libgbm-dev wget git

# --- 2. Getting Zig (0.16.0) ---
# Fixed naming convention for the 2026 download server
if [ ! -f "/usr/local/bin/river" ]; then
    if [ ! -d "zig-x86_64-linux-0.16.0" ]; then
        echo "--- Downloading Zig Toolchain (0.16.0) ---"
        wget https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz
        tar -xf zig-x86_64-linux-0.16.0.tar.xz
    fi
    export PATH=$PATH:$(pwd)/zig-x86_64-linux-0.16.0

    # --- 3. Building River ---
    if [ ! -d "river" ]; then
        echo "--- Cloning and Building River ---"
        git clone https://github.com/riverwm/river
        cd river
        zig build -Doptimize=ReleaseSafe
        sudo cp zig-out/bin/river /usr/local/bin/
        cd ..
    fi
fi

# --- 4. Setting up Rinux-WM ---
echo "--- Preparing Rinux-WM ---"
mkdir -p protocol src include

wget https://raw.githubusercontent.com/riverwm/river/master/protocol/river-window-management-v1.xml \
     -O protocol/river-window-management-v1.xml

if [ -f build.sh ]; then
    chmod +x build.sh
    echo "--- Running Build ---"
    ./build.sh
fi

echo "--- SUCCESS ---"