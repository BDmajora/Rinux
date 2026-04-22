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

# --- 3. River Setup (Master Branch) ---
if [ ! -d "river" ]; then
    git clone --recursive https://codeberg.org/river/river.git
fi
cd river
git fetch
git checkout master
git submodule update --init --recursive

# --- 4. Build & Install ---
echo "Building River (master) with Zig 0.14.0..."
rm -rf .zig-cache zig-out
# No patches needed—master is 0.14.0 compatible
zig build -Doptimize=ReleaseSafe

echo "Installing binaries..."
sudo cp zig-out/bin/river /usr/local/bin/
sudo cp zig-out/bin/riverctl /usr/local/bin/
cd ..

# --- 5. Config ---
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

echo "River (master) successfully built and installed."