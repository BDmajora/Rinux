#!/bin/sh
# config.sh - Rinux DE (Native Wayland Wine)

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"
TERM_CMD="foot"

# Target Resolution
RES_W=1280
RES_H=800

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Force Wine to use the Native Wayland Driver
# This adds the registry key required for Wine 9.0+ Wayland support
wine reg add "HKEY_CURRENT_USER\Software\Wine\Drivers" /v "Graphics" /t REG_SZ /d "wayland" /f

# 2. Start C++ WM Host
$RINUX_BIN &

# 3. Keybindings
riverctl map normal Super Q close
riverctl map normal Super E exit
riverctl map normal Super Return spawn "$TERM_CMD"

# 4. Global Style
riverctl default-border-width 0
riverctl background-color 0x000000

# 5. Autoboot Wine Desktop (Native Wayland Mode)
# We explicitly unset DISPLAY to prevent Xwayland fallback
riverctl spawn "env DISPLAY= wine explorer /desktop=Rinux,${RES_W}x${RES_H}"

EOF

chmod +x "$CONFIG_DIR/init"
echo "Rinux config updated: Wine Native Wayland enabled."
echo "Resolution set to ${RES_W}x${RES_H}."