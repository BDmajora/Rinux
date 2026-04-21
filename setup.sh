#!/bin/bash
set -e

# --- 1. Cleanup & Dependencies ---
echo "Cleaning up old Zig versions and installing dependencies..."
# Purge the apt version to ensure our manual install takes precedence
sudo apt remove --purge -y zig || true 
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
    scdoc

# --- 2. Install Zig 0.13.0 ---
ZIG_VERSION="0.13.0"
if ! command -v zig &> /dev/null || [[ "$(zig version)" != "${ZIG_VERSION}"* ]]; then
    echo "Installing Zig ${ZIG_VERSION}..."
    wget -q "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    tar -xf "zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    
    sudo rm -rf /opt/zig
    sudo mv "zig-linux-x86_64-${ZIG_VERSION}" /opt/zig
    sudo ln -sf /opt/zig/zig /usr/local/bin/zig
    rm "zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
fi

# --- 3. Clone & Checkout Stable River ---
RIVER_TAG="v0.3.5"
if [ ! -d "river" ]; then
    echo "Cloning River..."
    git clone --recursive https://github.com/riverwm/river
fi

cd river
echo "Ensuring River is on stable tag ${RIVER_TAG}..."
git fetch --tags
git checkout "$RIVER_TAG"
git submodule update --init --recursive

# Clear previous failed build artifacts
rm -rf .zig-cache zig-out

echo "Building River ${RIVER_TAG}..."
zig build -Doptimize=ReleaseSafe

echo "Installing binaries..."
sudo cp zig-out/bin/river /usr/local/bin/
sudo cp zig-out/bin/riverctl /usr/local/bin/
cd ..

# --- 4. Configuration ---
echo "Setting up River configuration..."
mkdir -p ~/.config/river
if [ ! -f ~/.config/river/init ]; then
    cp river/example/init ~/.config/river/init
    chmod +x ~/.config/river/init
fi

# --- 5. Scaffolding ---
echo "Setting up Workspace..."
mkdir -p protocol src include

if [ ! -f "protocol/river-window-management-v1.xml" ]; then
    wget -q "https://raw.githubusercontent.com/riverwm/river/${RIVER_TAG}/protocol/river-window-management-v1.xml" \
         -O protocol/river-window-management-v1.xml
fi

echo "SUCCESS: River built on stable tag ${RIVER_TAG} and workspace ready."