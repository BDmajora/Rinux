#!/bin/sh
CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"
TERM_CMD="foot"

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh
# 1. Start Rinux WM Host
$RINUX_BIN > /tmp/rinux.log 2>&1 &

# 2. Wait for Wayland socket to stabilize
sleep 3

# 3. Keybindings
riverctl default-border-width 0
riverctl map normal Super Return spawn $TERM_CMD
riverctl map normal Super E exit

# 4. Let Wine draw its own decorations, but DO NOT float it.
#    Floating bypasses your window manager entirely.
riverctl csd-filter-add "wine_explorer.exe"
riverctl csd-filter-add "wine*"

# 5. Background
riverctl background-color 0x4682b4

# 6. Launch Wine Desktop
riverctl spawn "env -u DISPLAY WINEWAYLAND=1 wine explorer /desktop=shell,1280x800"
EOF

chmod +x "$CONFIG_DIR/init"
echo "Rinux Desktop Configured. Restart River to boot into Wine."