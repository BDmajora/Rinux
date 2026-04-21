#!/bin/bash
set -e

# --- 1. Install Build Dependencies ---
echo "Installing dependencies for Debian 13..."
sudo apt update
sudo apt install -y \
    git \
    build-essential \
    pkg-config \
    wayland-protocols \
    libwayland-dev \
    libwlroots-dev \
    libinput-dev \
    libxkbcommon-dev \
    libpixman-1-dev \
    libudev-dev \
    libevdev-dev \
    wget \
    zig

# --- 2. Build River ---
if [ ! -d "river" ]; then
    git clone --recursive https://github.com/riverwm/river
fi

cd river
# clean any previous attempts
rm -rf .zig-cache zig-out

echo "Building River..."
zig build -Doptimize=ReleaseSafe

echo "Installing binaries..."
sudo cp zig-out/bin/river /usr/local/bin/
sudo cp zig-out/bin/riverctl /usr/local/bin/
cd ..

# --- 3. Configuration ---
mkdir -p ~/.config/river
if [ ! -f ~/.config/river/init ]; then
    # try to grab the example from the source folder we just downloaded
    cp river/example/init ~/.config/river/init
    chmod +x ~/.config/river/init
fi

# --- 4. Scaffolding (Rinux) ---
echo "Setting up Rinux Workspace..."
mkdir -p protocol src include

if [ ! -f "protocol/river-window-management-v1.xml" ]; then
    wget -q https://raw.githubusercontent.com/riverwm/river/master/protocol/river-window-management-v1.xml \
         -O protocol/river-window-management-v1.xml
fi

echo "SUCCESS: River built and Rinux workspace ready"