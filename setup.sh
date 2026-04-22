#!/bin/bash
set -e

# --- 1. Dependencies ---
echo "Installing system dependencies..."
sudo apt update
sudo apt install -y build-essential gcc g++ libwayland-dev libwayland-bin wayland-protocols pkg-config libwlroots-0.18-dev libxkbcommon-dev libpixman-1-dev libinput-dev libudev-dev libgbm-dev wget git scdoc foot wine

# --- 2. Install Zig 0.14.0 ---
# 0.14.0 is required to correctly parse the modern multihashes in the repository.
ZIG_VERSION="0.14.0"
if ! command -v zig &> /dev/null || [[ "$(zig version)" != "${ZIG_VERSION}"* ]]; then
    echo "Installing Zig ${ZIG_VERSION}..."
    wget -q "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    tar -xf "zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    sudo rm -rf /opt/zig && sudo mv "zig-linux-x86_64-${ZIG_VERSION}" /opt/zig
    sudo ln -sf /opt/zig/zig /usr/local/bin/zig
    rm "zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
fi

# --- 3. River Setup (Tagged v0.4.0) ---
if [ ! -d "river" ]; then
    git clone --recursive https://codeberg.org/river/river.git
fi
cd river
git fetch --tags
git reset --hard v0.4.0
git submodule update --init --recursive

# --- 4. The Surgical Patches for Zig 0.14.0 Compatibility ---

# Fix A: Decouple versioning from the ZON manifest
# This bypasses the '@import of ZON must have a known result type' error.
echo "Patching build.zig to hardcode version..."
sed -i 's/const manifest = @import("build.zig.zon");/\/\/ manifest removed/' build.zig
sed -i 's/const version = manifest.version;/const version = "0.4.0";/' build.zig

# Fix B: Populate the cache so we can patch dependencies
# Errors here are expected as we haven't patched the dependencies yet.
echo "Fetching dependencies..."
zig build --fetch || true

# Fix C: Unlock and fix the 'ArrayList.empty' error in the global cache
# This fixes the 'no member named empty' error in wayland dependencies.
echo "Unlocking and patching Zig cache..."
chmod -R u+w ~/.cache/zig/p/ 2>/dev/null || true
find ~/.cache/zig/p -name "scanner.zig" -exec sed -i 's/\.empty/.{}/g' {} + 2>/dev/null || true

# --- 5. Build & Install ---
echo "Building River v0.4.0 with Zig 0.14.0..."
rm -rf .zig-cache zig-out
# Now that we've patched the cache and build script, this should complete.
zig build -Doptimize=ReleaseSafe

echo "Installing binaries..."
sudo cp zig-out/bin/river /usr/local/bin/
sudo cp zig-out/bin/riverctl /usr/local/bin/
cd ..

# --- 6. Configuration ---
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

echo "River v0.4.0 successfully built and installed using Zig 0.14.0 patches."