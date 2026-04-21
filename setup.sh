#!/bin/bash
set -e

echo "--- 1. Installing Debian System Dependencies ---"
sudo apt update
# Added meson and ninja-build required for compiling updated protocols
sudo apt install -y build-essential gcc g++ libwayland-dev libwayland-bin \
    wayland-protocols pkg-config libwlroots-0.18-dev libxkbcommon-dev \
    libpixman-1-dev libinput-dev libudev-dev libgbm-dev wget git \
    meson ninja-build scdoc

# --- 1.5 Upgrading Wayland Protocols (Fixes color_manager_v1 error) ---
echo "--- Ensuring up-to-date Wayland Protocols ---"
if [ ! -d "wayland-protocols" ]; then
    git clone https://gitlab.freedesktop.org/wayland/wayland-protocols.git
fi
cd wayland-protocols
# Configure and install the latest protocols globally
meson setup build --prefix=/usr/local --reconfigure || meson setup build --prefix=/usr/local
sudo ninja -C build install
cd ..

# CRITICAL: Tell the system where to find the newly installed protocols
export PKG_CONFIG_PATH="/usr/local/share/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"


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
if [ ! -f "/usr/local/bin/river" ]; then
    echo "--- Building River ---"
    if [ ! -d "river" ]; then
        git clone https://github.com/riverwm/river
    fi
    cd river
    
    # Wipe the cache to ensure it forgets the previous failed build
    echo "--- Clearing old build caches ---"
    rm -rf .zig-cache zig-out
    
    # Build
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