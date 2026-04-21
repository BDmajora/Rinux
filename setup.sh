#!/bin/bash
set -e

echo "--- 1. Installing Debian System Dependencies ---"
sudo apt update
sudo apt install -y build-essential gcc g++ libwayland-dev libwayland-bin \
    wayland-protocols pkg-config libwlroots-0.18-dev libxkbcommon-dev \
    libpixman-1-dev libinput-dev libudev-dev libgbm-dev wget git

# --- 2. Getting Zig (0.16.0) ---
ZIG_FOLDER="zig-x86_64-linux-0.16.0"
if [ ! -d "$ZIG_FOLDER" ]; then
    echo "--- Downloading Zig Toolchain (0.16.0) ---"
    wget "https://ziglang.org/download/0.16.0/$ZIG_FOLDER.tar.xz"
    tar -xf "$ZIG_FOLDER.tar.xz"
fi

# Add Zig to the current script's PATH
export PATH="$PATH:$(pwd)/$ZIG_FOLDER"

# --- 3. Building and Installing River ---
# This ensures River is installed system-wide so the command works later
if [ ! -f "/usr/local/bin/river" ]; then
    echo "--- Building River ---"
    if [ ! -d "river" ]; then
        git clone https://github.com/riverwm/river
    fi
    cd river
    zig build -Doptimize=ReleaseSafe
    echo "--- Installing River to /usr/local/bin ---"
    sudo cp zig-out/bin/river /usr/local/bin/
    sudo cp zig-out/bin/riverctl /usr/local/bin/
    cd ..
else
    echo "--- River is already installed at /usr/local/bin/river ---"
fi

# --- 4. Preparing Rinux-WM Environment ---
echo "--- Preparing Rinux-WM Protocols ---"
mkdir -p protocol src include

# Fetch the protocol XML
wget -q https://raw.githubusercontent.com/riverwm/river/master/protocol/river-window-management-v1.xml \
     -O protocol/river-window-management-v1.xml

echo "--- SUCCESS ---"
echo "Setup complete. You can now run ./build.sh to compile Rinux-WM."