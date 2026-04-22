#!/bin/sh
# config.sh - Rinux-WM Wine 11 Desktop Bootloader

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"
TERM_CMD="foot"

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Start Rinux WM Host
$RINUX_BIN > /tmp/rinux.log 2>&1 &

# 2. Wait for Wayland socket and EGL to stabilize
sleep 3

# 3. River Keybindings & Rules
riverctl default-border-width 0
riverctl map normal Super Return spawn $TERM_CMD
riverctl map normal Super E exit

# CRITICAL: Prevent River from putting title bars/borders on your Wine Desktop
riverctl csd-filter-add "wine*"
riverctl rule-add -app-id "wine*" float

# 4. Set background color (Steel Blue)
riverctl background-color 0x4682b4

# 5. Launch Wine Desktop (Rinux Mode)
# env -u DISPLAY forces Wine 11 to use the Wayland driver
riverctl spawn "env -u DISPLAY WINEWAYLAND=1 wine explorer /desktop=shell,1280x800"

EOF

chmod +x "$CONFIG_DIR/init"
echo "Rinux Desktop Configured. Restart River to boot into Wine."