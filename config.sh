#!/bin/bash
set -e

# --- Configuration Paths ---
CONFIG_DIR="$HOME/.config/river"
RINUX_BIN="$HOME/Rinux/rinux-wm"

echo "[Rinux] Deploying clean River configuration..."

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# --- Atomic Init Generation ---
# This overwrites the existing init to ensure NO other WMs/tile-engines run.
cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Environment Sanitization
# Ensure Wayland globals are available for the WM connection
export WAYLAND_DISPLAY="\${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="\${XDG_RUNTIME_DIR:-/run/user/\$(id -u)}"

# 2. Kill Competition
# If rivertile or another instance is hanging around, kill it so we can bind the protocol.
killall rivertile 2>/dev/null
killall rinux-wm 2>/dev/null

# 3. Launch Rinux WM
# Launching the binary you already compiled.
$RINUX_BIN > /tmp/rinux.log 2>&1 &

# 4. Protocol Handshake Wait
sleep 1

# 5. Global River Settings
riverctl default-border-width 0
riverctl background-color 0x4682b4

# 6. Keybindings
# Using 'foot' as the default terminal; adjust if you use alacritty/kitty.
riverctl map normal Super Return spawn "foot"
riverctl map normal Super E exit

# 7. Wine Environment & Desktop Launch
# csd-filter-add tells River to let Wine handle its own window decorations.
riverctl csd-filter-add "wine*"
riverctl spawn "env -u DISPLAY WINEWAYLAND=1 wine explorer /desktop=shell,1280x800"
EOF

# --- Final Permissions ---
chmod +x "$CONFIG_DIR/init"

echo "[Rinux] Done. Current config will now prioritize rinux-wm and ignore rivertile."
echo "[Rinux] Location: $CONFIG_DIR/init"