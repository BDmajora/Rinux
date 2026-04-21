#!/bin/bash
set -e

echo "--- 1. Installing Debian System Dependencies ---"
sudo apt update
sudo apt install -y build-essential gcc g++ libwayland-dev libwayland-bin \
    wayland-protocols pkg-config libwlroots-0.18-dev libxkbcommon-dev \
    libpixman-1-dev libinput-dev libudev-dev libgbm-dev wget git scdoc

# --- 2. Fix the wp_color_manager_v1 version error ---
echo "--- Injecting updated color-management protocol ---"
# We download the v2 protocol file directly from the source
# and place it into the staging directory where River looks for it.
COLOR_PROTO_DIR="/usr/share/wayland-protocols/staging/color-management"
sudo mkdir -p "$COLOR_PROTO_DIR"
sudo wget -q https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/staging/color-management/color-management-v1.xml \
     -O "$COLOR_PROTO_DIR/color-management-v1.xml"

# --- 3. Getting Zig (0.16.0) ---
ZIG_FOLDER="zig-x86_64-linux-0.16.0"
if [ ! -d "$ZIG_FOLDER" ]; then
    echo "--- Downloading Zig Toolchain (0.16.0) ---"
    wget "https://ziglang.org/download/0.16.0/$ZIG_FOLDER.tar.xz"
    tar -xf "$ZIG_FOLDER.tar.xz"
fi

export PATH="$PATH:$(pwd)/$ZIG_FOLDER"

# --- 4. Building and Installing River ---
if [ ! -f "/usr/local/bin/river" ]; then
    echo "--- Building River ---"
    if [ ! -d "river" ]; then
        git clone https://github.com/riverwm/river
    fi
    cd river
    
    # Force a clean build to recognize the new protocol file
    rm -rf .zig-cache zig-out
    
    zig build -Doptimize=ReleaseSafe
    
    echo "--- Installing River to /usr/local/bin ---"
    sudo cp zig-out/bin/river /usr/local/bin/
    sudo cp zig-out/bin/riverctl /usr/local/bin/
    cd ..
else
    echo "--- River is already installed ---"
fi

# --- 5. Preparing Rinux-WM Environment ---
echo "--- Preparing Rinux-WM Protocols ---"
mkdir -p protocol src include

wget -q https://raw.githubusercontent.com/riverwm/river/master/protocol/river-window-management-v1.xml \
     -O protocol/river-window-management-v1.xml

echo "--- SUCCESS ---"