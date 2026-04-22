#!/bin/bash
# config.sh - Final Wayland-First Configuration

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"

echo "Configuring Wine for Native Wayland (Wine 10+ style)..."

# 1. Initialize the prefix (quietly)
wineboot -i 

# 2. Set Registry to prioritize Wayland over X11
# This tells Wine: "Try Wayland first, fall back to x11 if you must"
wine reg add "HKCU\Software\Wine\Drivers" /v Graphics /t REG_SZ /d "wayland,x11" /f

echo "Generating River init file..."

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Start Rinux-WM
$RINUX_BIN &

# 2. Window Rules
riverctl rule-add -app-id "wine*" float
riverctl csd-filter-add "wine*"

# 3. Keybindings
riverctl map normal Super Q close
riverctl map normal Super Return spawn foot
riverctl map normal Super E exit

# 4. Launch Wine Desktop
# We unset DISPLAY by setting it to an empty string. 
# This forces Wine 10 to use the Wayland driver.
env DISPLAY= wine explorer /desktop=Rinux,1280x800 explorer.exe &

riverctl background-color 0x4682b4
EOF

chmod +x "$CONFIG_DIR/init"
echo "---"
echo "Config complete. Run 'river' to start your Native Wayland DE."