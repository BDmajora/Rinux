#!/bin/sh
# config.sh - Updated for Wine Autoboot

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"
TERM_CMD="foot"

# Define the Wine Desktop resolution to match your C++ code
RES_W=1280
RES_H=800

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Launch the C++ Window Manager Host
$RINUX_BIN &

# 2. Wait a split second for the WM to register with the compositor
sleep 0.5

# 3. Autoboot Wine Virtual Desktop
# This creates a "monocle" style Wine environment
wine explorer /desktop=Rinux,${RES_W}x${RES_H} &

# 4. Native River Rules & Styles
riverctl default-border-width 2
riverctl border-color-focused 0x93a1a1
riverctl border-color-unfocused 0x586e75

# 5. Keybindings
riverctl map normal Super Q close
riverctl map normal Super E exit
riverctl map normal Super Return spawn $TERM_CMD

# Default background
riverctl background-color 0x002b36
EOF

chmod +x "$CONFIG_DIR/init"
echo "River configuration reset."
echo "Autoboot set: Wine Virtual Desktop ($RES_W x $RES_H)"
echo "Emergency Terminal: Super+Return | Exit: Super+E"