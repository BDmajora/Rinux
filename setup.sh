#!/bin/bash
set -e

# --- 1. Install Build Dependencies ---
echo "Installing dependencies for Ubuntu 25.10..."
sudo apt update
# Removed 'zig' from apt install since the Ubuntu repo version is too old for River
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
    scdoc

# --- 2. Install Correct Zig Version ---
ZIG_VERSION="0.13.0"
echo "Ensuring Zig ${ZIG_VERSION} is installed..."

# Check if Zig is installed and matches the required version
if ! command -v zig &> /dev/null || [[ "$(zig version)" != "${ZIG_VERSION}"* ]]; then
    echo "Downloading Zig ${ZIG_VERSION}..."
    wget -q "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    tar -xf "zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    
    # Move to /opt and create a symlink in /usr/local/bin
    sudo rm -rf /opt/zig
    sudo mv "zig-linux-x86_64-${ZIG_VERSION}" /opt/zig
    sudo ln -sf /opt/zig/zig /usr/local/bin/zig
    
    # Clean up the downloaded tarball
    rm "zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    echo "Zig ${ZIG_VERSION} installed successfully."
else
    echo "Zig $(zig version) is already installed."
fi

# --- 3. Build River ---
if [ ! -d "river" ]; then
    git clone --recursive https://github.com/riverwm/river
fi

cd river
# Clear previous failed build artifacts
rm -rf .zig-cache zig-out

echo "Building River..."
zig build -Doptimize=ReleaseSafe

echo "Installing binaries..."
sudo cp zig-out/bin/river /usr/local/bin/
sudo cp zig-out/bin/riverctl /usr/local/bin/
cd ..

# --- 4. Configuration ---
echo "Setting up River configuration..."
mkdir -p ~/.config/river
if [ ! -f ~/.config/river/init ]; then
    # Use the example init from the cloned source
    cp river/example/init ~/.config/river/init
    chmod +x ~/.config/river/init
fi

# --- 5. Scaffolding (Rinux) ---
echo "Setting up Rinux Workspace..."
mkdir -p protocol src include

if [ ! -f "protocol/river-window-management-v1.xml" ]; then
    wget -q https://raw.githubusercontent.com/riverwm/river/master/protocol/river-window-management-v1.xml \
         -O protocol/river-window-management-v1.xml
fi

echo "SUCCESS: River built and Rinux workspace ready"