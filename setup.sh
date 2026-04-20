#!/bin/bash
set -e

echo "--- 1. Installing Debian System Dependencies ---"
sudo apt update
sudo apt install -y build-essential gcc g++ libwayland-dev libwayland-bin \
    wayland-protocols pkg-config libwlroots-dev libxkbcommon-dev \
    libpixman-1-dev libinput-dev libudev-dev libgbm-dev wget git scdoc

# --- 2. Getting Zig (0.16.0 required for current River) ---
ZIG_VER="0.16.0"
ZIG_FOLDER="zig-x86_64-linux-$ZIG_VER"

if [ ! -f "/usr/local/bin/river" ]; then
    if [ ! -d "$ZIG_FOLDER" ]; then
        echo "--- Downloading Zig Toolchain ($ZIG_VER) ---"
        wget "https://ziglang.org/download/$ZIG_VER/$ZIG_FOLDER.tar.xz"
        tar -xf "$ZIG_FOLDER.tar.xz"
    fi
    # Add current folder's zig to path for this session
    export PATH="$PATH:$(pwd)/$ZIG_FOLDER"

    # --- 3. Building River (The Host Compositor) ---
    if [ ! -d "river" ]; then
        echo "--- Cloning and Building River ---"
        git clone https://github.com/riverwm/river
        cd river
        zig build -Doptimize=ReleaseSafe -Dxwayland=true
        sudo cp zig-out/bin/river /usr/local/bin/
        cd ..
    fi
fi

# --- 4. Setting up Rinux-WM ---
echo "--- Preparing Rinux-WM ---"
mkdir -p protocol src include

# Fetch the specific protocol file your code needs
# We use the GitHub mirror for stability
wget https://raw.githubusercontent.com/riverwm/river/master/protocol/river-window-management-v1.xml \
     -O protocol/river-window-management-v1.xml

# Make sure your existing build.sh is executable and run it
if [ -f build.sh ]; then
    chmod +x build.sh
    echo "--- Running Rinux-WM Build ---"
    ./build.sh
else
    echo "--- Notice: build.sh not found, skipping Rinux-WM compilation ---"
fi

echo "--- SUCCESS ---"
echo "To test: Type 'river' to start the compositor,"
echo "then run './rinux-wm' from a terminal (like foot) inside River."