#!/bin/bash
# config.sh - Final Wayland-First Configuration

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"

echo "Generating River init file..."

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Start Rinux-WM
$RINUX_BIN &

# 2. Initialize Prefix & Set Registry for Wayland
# Doing this inside init ensures the Wayland compositor is actually running!
wine reg add "HKCU\Software\Wine\Drivers" /v Graphics /t REG_SZ /d "wayland,x11" /f

# 3. Window Rules
riverctl rule-add -app-id "wine*" float
riverctl csd-filter-add "wine*"

# 4. Keybindings
riverctl map normal Super Q close
riverctl map normal Super Return spawn foot
riverctl map normal Super E exit

# 5. Launch Wine Desktop
env DISPLAY= wine explorer /desktop=Rinux,1280x800 explorer.exe &

riverctl background-color 0x4682b4
EOF

chmod +x "$CONFIG_DIR/init"
echo "---"
echo "Config complete. Run 'river' to start your Native Wayland DE."