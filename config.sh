#!/bin/sh
# config.sh - Clean River Environment (Wine Disabled)

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# Launch C++ Host
$RINUX_BIN &

# Native River Rules
riverctl default-border-width 2
riverctl border-color-focused 0x93a1a1
riverctl border-color-unfocused 0x586e75

# Keybindings
riverctl map normal Super Q close
riverctl map normal Super E exit

# Default background
riverctl background-color 0x002b36
EOF

chmod +x "$CONFIG_DIR/init"
echo "River configuration reset. Wine components removed."