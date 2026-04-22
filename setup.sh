#!/bin/bash
set -e

# --- 1. Cleanup Old Versions ---
# Remove binaries from /usr/bin to prevent path conflicts
echo "Cleaning up old River binaries..."
sudo rm -f /usr/bin/river /usr/bin/riverctl /usr/bin/rivertile

# --- 2. System Runtime Dependencies ---
echo "Installing runtime dependencies..."
sudo apt update
sudo apt install -y libwayland-client0 libwlroots-0.18-dev libxkbcommon0 \
    libpixman-1-0 libinput10 libudev1 libgbm1 wget git wine scdoc

# --- 3. Download Pre-compiled River v0.4.0 ---
echo "Downloading River v0.4.0 binary..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
wget -q https://codeberg.org/river/river/releases/download/v0.4.0/river-v0.4.0-linux-x86_64.tar.gz

# --- 4. Install Binaries ---
echo "Extracting and installing to /usr/local/bin..."
tar -xf river-v0.4.0-linux-x86_64.tar.gz
sudo cp river-v0.4.0-linux-x86_64/river /usr/local/bin/
sudo cp river-v0.4.0-linux-x86_64/riverctl /usr/local/bin/
sudo cp river-v0.4.0-linux-x86_64/rivertile /usr/local/bin/

# Install man pages
sudo mkdir -p /usr/local/share/man/man1/
sudo cp river-v0.4.0-linux-x86_64/river.1 /usr/local/share/man/man1/
sudo cp river-v0.4.0-linux-x86_64/riverctl.1 /usr/local/share/man/man1/

# --- 5. Configuration Cleanup ---
mkdir -p ~/.config/river

# If the init file doesn't exist, grab the default from the binary pack
if [ ! -f ~/.config/river/init ]; then
    cp river-v0.4.0-linux-x86_64/init.example ~/.config/river/init
    chmod +x ~/.config/river/init
fi

# --- 6. Apply Rinux Customizations ---
# Ensure we don't duplicate the block if it already exists
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

echo "Clean install complete. Use Super+Shift+E to exit River."