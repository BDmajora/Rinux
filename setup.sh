#!/bin/bash
set -e

# --- 1. Cleanup & Dependencies ---
echo "Cleaning up old Zig versions and installing dependencies..."
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
    scdoc \
    foot \
    wine

# --- 2. Install Zig 0.14.0 (required by River 0.4.0) ---
ZIG_VERSION="0.14.0"
if ! command -v zig &> /dev/null || [[ "$(zig version)" != "${ZIG_VERSION}"* ]]; then
    echo "Installing Zig ${ZIG_VERSION}..."
    wget -q "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    tar -xf "zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    sudo rm -rf /opt/zig
    sudo mv "zig-linux-x86_64-${ZIG_VERSION}" /opt/zig
    sudo ln -sf /opt/zig/zig /usr/local/bin/zig
    rm "zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
else
    echo "Zig ${ZIG_VERSION} already installed."
fi

echo "Zig version: $(zig version)"

# --- 3. Clone & Build River 0.4.0 ---
RIVER_TAG="v0.4.0"
if [ ! -d "river" ]; then
    echo "Cloning River..."
    git clone --recursive https://codeberg.org/river/river.git
fi

cd river
echo "Checking out River ${RIVER_TAG}..."
git fetch --tags
git checkout "$RIVER_TAG"
git submodule update --init --recursive

# PATCH: Fix Zig 0.14.0 'known result type' error for ZON import
# This satisfies the new compiler requirement for explicit struct types on ZON imports.
echo "Patching build.zig for Zig 0.14.0 compatibility..."
sed -i 's/const manifest = @import("build.zig.zon");/const manifest: struct { version: []const u8 } = @import("build.zig.zon");/' build.zig

# Clear previous build artifacts
rm -rf .zig-cache zig-out

echo "Building River ${RIVER_TAG}..."
zig build -Doptimize=ReleaseSafe

echo "Installing River binaries..."
sudo cp zig-out/bin/river /usr/local/bin/
sudo cp zig-out/bin/riverctl /usr/local/bin/
cd ..

# Verify
echo "River version: $(river -version)"

# --- 4. Configuration ---
echo "Setting up River configuration..."
mkdir -p ~/.config/river
if [ ! -f ~/.config/river/init ]; then
    cp river/example/init ~/.config/river/init
    chmod +x ~/.config/river/init
fi

# --- 5. Get River 0.4.0 protocol XML ---
echo "Setting up workspace..."
mkdir -p protocol src include

echo "Downloading River 0.4.0 window management protocol..."
wget -q "https://codeberg.org/river/river/raw/tag/${RIVER_TAG}/protocol/river-window-management-v1.xml" \
    -O protocol/river-window-management-v1.xml

echo "Protocol saved to protocol/river-window-management-v1.xml"

# --- 6. Update River init ---
echo "Updating River init config..."
CONFIG_FILE="$HOME/.config/river/init"

if ! grep -q "rinux-wm" "$CONFIG_FILE"; then
    cat >> "$CONFIG_FILE" <<'EOF'

# Rinux WM + Wine Desktop
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
$HOME/Rinux/rinux-wm > /tmp/rinux.log 2>&1 &
sleep 2
riverctl default-border-width 0
riverctl csd-filter-add "wine*"
riverctl background-color 0x4682b4
riverctl spawn "env -u DISPLAY WINEWAYLAND=1 wine explorer /desktop=shell,1280x800"
EOF
    echo "[+] Config updated: Rinux-WM added to $CONFIG_FILE"
else
    echo "[SKIP] Rinux-WM already present in config."
fi

echo "---"
echo "SUCCESS: River ${RIVER_TAG} built and installed."
echo "Now run: cd ~/Rinux && ./build.sh"
echo "Then restart River to test."