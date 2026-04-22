#!/bin/bash
# config.sh - Configures River to host the Wine Desktop

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"

# Path to your compiled WM
RINUX_BIN="$HOME/Rinux/rinux-wm"

echo "Generating River init file..."

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Start your custom Window Manager in the background
$RINUX_BIN &

# 2. Keybindings (Minimalist)
riverctl map normal Super Q close
riverctl map normal Super Return spawn foot
riverctl map normal Super E exit

# 3. Launch Wine Desktop
# We let Rinux-WM handle the sizing, so we just launch it bare
wine explorer /desktop=Rinux &

# 4. Set background color (Steel Blue)
riverctl background-color 0x4682b4
EOF

chmod +x "$CONFIG_DIR/init"
echo "Config complete. Run 'river' to start your Wine DE."