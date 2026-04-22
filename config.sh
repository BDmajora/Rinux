#!/bin/bash
set -e

# --- Configuration Paths ---
CONFIG_DIR="$HOME/.config/river"
RINUX_BIN="$HOME/Rinux/rinux-wm"
REG_FILE="/tmp/rinux_layout.reg"

echo "[Rinux] Deploying clean River configuration..."

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# --- Create the Registry Fix ---
# This forces the internal Wine taskbar to the bottom (03) of the 1280x800 area.
cat <<EOF > "$REG_FILE"
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3]
"Settings"=hex:30,00,00,00,fe,ff,ff,ff,03,00,00,00,03,00,00,00,3e,00,00,00,28,\\
  00,00,00,00,00,00,00,e8,02,00,00,00,05,00,00,20,03,00,00,60,00,00,00,01,00,\\
  00,00
EOF

# --- Atomic Init Generation ---
cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Environment Sanitization
export WAYLAND_DISPLAY="\${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="\${XDG_RUNTIME_DIR:-/run/user/\$(id -u)}"

# 2. Kill Competition
killall rivertile 2>/dev/null
killall rinux-wm 2>/dev/null

# 3. Apply Wine Registry Fix
# We do this before the WM or Shell starts to ensure the environment is ready.
wine regedit /s "$REG_FILE"

# 4. Launch Rinux WM
$RINUX_BIN > /tmp/rinux.log 2>&1 &

# 5. Protocol Handshake Wait
sleep 1

# 6. Global River Settings
riverctl default-border-width 0
riverctl background-color 0x4682b4

# 7. Keybindings
riverctl map normal Super Return spawn "foot"
riverctl map normal Super E exit

# 8. Wine Environment & Desktop Launch
riverctl csd-filter-add "wine*"

# Launching with fixed geometry. 
# WINEWAYLAND=1 ensures it uses the Wayland driver instead of XWayland.
riverctl spawn "env -u DISPLAY WINEWAYLAND=1 wine explorer /desktop=shell,1280x800"
EOF

# --- Final Permissions ---
chmod +x "$CONFIG_DIR/init"

echo "[Rinux] Done. Registry patched and init generated."
echo "[Rinux] Location: $CONFIG_DIR/init"