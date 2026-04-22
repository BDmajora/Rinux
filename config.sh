#!/bin/sh
# config.sh - Cleaned River Wine Configuration

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"

echo "Generating River init..."

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# Launch your C++ Host first
$RINUX_BIN &

# Force Wayland Driver
wine reg add "HKCU\\Software\\Wine\\Drivers" /v Graphics /t REG_SZ /d "wayland" /f

# Native River Rules
riverctl default-border-width 0
riverctl rule-add -app-id "org.winehq.wine" float

# Keybindings
riverctl map normal Super Q close
riverctl map normal Super E exit

# Launch Wine
# Removed shell registry overrides and explicit /desktop flags
unset DISPLAY
env WAYLAND_DISPLAY=\$WAYLAND_DISPLAY wine explorer &

riverctl background-color 0x000000
EOF

chmod +x "$CONFIG_DIR/init"
echo "Done."