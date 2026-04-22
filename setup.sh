#!/bin/bash
set -e

# --- 1. Dependencies ---
echo "Installing system dependencies..."
sudo apt update
sudo apt install -y build-essential gcc g++ libwayland-dev libwayland-bin wayland-protocols pkg-config libwlroots-0.18-dev libxkbcommon-dev libpixman-1-dev libinput-dev libudev-dev libgbm-dev wget git scdoc foot wine

# --- 2. Install Zig 0.11.0 ---
ZIG_VERSION="0.11.0"
if ! command -v zig &> /dev/null || [[ "$(zig version)" != "${ZIG_VERSION}"* ]]; then
    echo "Installing Zig ${ZIG_VERSION}..."
    wget -q "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    tar -xf "zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    sudo rm -rf /opt/zig 
    sudo mv "zig-linux-x86_64-${ZIG_VERSION}" /opt/zig
    sudo ln -sf /opt/zig/zig /usr/local/bin/zig
    rm "zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
fi
echo "Current Zig version: $(zig version)"

# --- 3. River Setup (Tagged v0.4.0) ---
if [ ! -d "river" ]; then
    git clone --recursive https://codeberg.org/river/river.git
fi
cd river
git fetch --tags
git reset --hard v0.4.0
git submodule update --init --recursive

# --- 4. Surgical Patches ---

# Fix A: Update manifest name from enum literal to string literal
# This fixes the "expected string literal" error in build.zig.zon
echo "Patching build.zig.zon..."
sed -i 's/\.name = \.river,/\.name = "river",/' build.zig.zon

# Fix B: Fetch dependencies to populate cache
echo "Fetching dependencies..."
zig build --fetch || true

# Fix C: Unlock and patch cached dependencies
echo "Unlocking and patching Zig cache..."
chmod -R u+w ~/.cache/zig/p/ 2>/dev/null || true
find ~/.cache/zig/p -name "scanner.zig" -exec sed -i 's/\.empty/.{}/g' {} + 2>/dev/null || true

# --- 5. Build & Install ---
echo "Building River v0.4.0 with Zig 0.11.0..."
rm -rf .zig-cache zig-out
zig build -Doptimize=ReleaseSafe

echo "Installing binaries..."
sudo cp zig-out/bin/river /usr/local/bin/
sudo cp zig-out/bin/riverctl /usr/local/bin/
cd ..

# --- 6. Protocol and Config ---
mkdir -p protocol
wget -q "https://codeberg.org/river/river/raw/tag/v0.4.0/protocol/river-window-management-v1.xml" -O protocol/river-window-management-v1.xml

mkdir -p ~/.config/river
if [ ! -f ~/.config/river/init ]; then
    cp river/example/init ~/.config/river/init
    chmod +x ~/.config/river/init
fi

if ! grep -q "rinux-wm" ~/.config/river/init; then
    cat >> ~/.config/river/init <<'EOF'

# Rinux WM Setup
$HOME/Rinux/rinux-wm > /tmp/rinux.log 2>&1 &
sleep 2
riverctl csd-filter-add "wine*"
riverctl background-color 0x4682b4
riverctl spawn "env -u DISPLAY WINEWAYLAND=1 wine explorer /desktop=shell,1280x800"
EOF
fi

echo "Success. River v0.4.0 is now installed via Zig 0.11.0."