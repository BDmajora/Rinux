#!/bin/bash
set -e

# --- 1. Dependencies ---
echo "Installing dependencies..."
sudo apt update
sudo apt install -y build-essential gcc g++ libwayland-dev libwayland-bin wayland-protocols pkg-config libwlroots-0.18-dev libxkbcommon-dev libpixman-1-dev libinput-dev libudev-dev libgbm-dev wget git scdoc foot wine

# --- 2. Force Zig 0.14.0 ---
ZIG_VERSION="0.14.0"
if ! command -v zig &> /dev/null || [[ "$(zig version)" != "${ZIG_VERSION}"* ]]; then
    echo "Installing Zig ${ZIG_VERSION}..."
    wget -q "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    tar -xf "zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    sudo rm -rf /opt/zig && sudo mv "zig-linux-x86_64-${ZIG_VERSION}" /opt/zig
    sudo ln -sf /opt/zig/zig /usr/local/bin/zig
fi

# --- 3. River Setup ---
RIVER_TAG="v0.4.0"
[ ! -d "river" ] && git clone --recursive https://codeberg.org/river/river.git
cd river
git fetch --tags
git checkout "$RIVER_TAG"
git submodule update --init --recursive

# --- 4. The Surgical Patches ---

# Fix A: Decouple build.zig from build.zig.zon
echo "Patching build.zig to hardcode version..."
sed -i 's/const manifest = @import("build.zig.zon");/\/\/ manifest removed/' build.zig
sed -i 's/const version = manifest.version;/const version = "0.4.0";/' build.zig

# Fix B: Fetch dependencies so they exist in the cache
echo "Fetching dependencies..."
zig build --fetch || true

# Fix C: Recursively unlock the cache directories and patch the error
echo "Unlocking Zig cache directories..."
chmod -R u+w ~/.cache/zig/p/ 2>/dev/null || true

echo "Patching cached dependencies for Zig 0.14.0 compatibility..."
find ~/.cache/zig/p -name "scanner.zig" -exec sed -i 's/\.empty/.{}/g' {} + 2>/dev/null || true

# --- 5. Build & Install ---
echo "Building River with Zig 0.14.0..."
rm -rf .zig-cache zig-out
zig build -Doptimize=ReleaseSafe

echo "Installing binaries..."
sudo cp zig-out/bin/river /usr/local/bin/
sudo cp zig-out/bin/riverctl /usr/local/bin/
cd ..

# --- 6. Protocols & Config ---
mkdir -p protocol
wget -q "https://codeberg.org/river/river/raw/tag/${RIVER_TAG}/protocol/river-window-management-v1.xml" -O protocol/river-window-management-v1.xml

mkdir -p ~/.config/river
[ ! -f ~/.config/river/init ] && cp river/example/init ~/.config/river/init && chmod +x ~/.config/river/init

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

echo "River 0.4.0 successfully forced onto Zig 0.14.0."