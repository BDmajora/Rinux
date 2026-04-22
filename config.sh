#!/bin/sh
# config.sh - Rinux-WM Wine 11 Desktop Bootloader

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"
TERM_CMD="foot"

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Start Rinux WM Host
# This launches your custom monocle layout manager
$RINUX_BIN > /tmp/rinux.log 2>&1 &

# 2. Wait for Wayland socket and EGL to stabilize
sleep 3

# 3. River Keybindings & Rules
riverctl default-border-width 0
riverctl map normal Super Return spawn $TERM_CMD
riverctl map normal Super E exit

# CRITICAL: Prevent River from putting title bars or borders on the Wine Desktop.
# The csd-filter-add tells River to let the application handle its own decorations.
riverctl csd-filter-add "wine_explorer.exe"
riverctl csd-filter-add "wine*"

# Force the explorer and taskbar to float so they don't trigger the layout() function.
riverctl rule-add -app-id "wine_explorer.exe" float
riverctl rule-add -app-id "wine*" float

# 4. Set background color (Steel Blue)
riverctl background-color 0x4682b4

# 5. Launch Wine Desktop (Rinux Mode)
# env -u DISPLAY forces Wine 11 to use the native Wayland driver instead of XWayland.
riverctl spawn "env -u DISPLAY WINEWAYLAND=1 wine explorer /desktop=shell,1280x800"

EOF

chmod +x "$CONFIG_DIR/init"
echo "Rinux Desktop Configured. Restart River to boot into Wine."