#!/bin/bash
set -e

# --- 1. Install Build Dependencies ---
echo "Installing dependencies for Ubuntu 25.10..."
sudo apt update
sudo apt install -y \
    build-essential \
    gcc \
    g++ \
    libwayland-dev \
    libwayland-bin \
    wayland-protocols \
    pkg-config \
    libwlroots-0.18-dev \
    libxkbcommon-dev \
    libpixman-1-dev \
    libinput-dev \
    libudev-dev \
    libgbm-dev \
    wget \
    git \
    scdoc \
    zig

# --- 2. Build River ---
if [ ! -d "river" ]; then
    git clone --recursive https://github.com/riverwm/river
fi

cd river
# Clear previous build artifacts
rm -rf .zig-cache zig-out

echo "Building River..."
zig build -Doptimize=ReleaseSafe

echo "Installing binaries..."
sudo cp zig-out/bin/river /usr/local/bin/
sudo cp zig-out/bin/riverctl /usr/local/bin/
cd ..

# --- 3. Configuration ---
echo "Setting up River configuration..."
mkdir -p ~/.config/river
if [ ! -f ~/.config/river/init ]; then
    # Use the example init from the cloned source
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