#!/bin/bash
# config.sh - Configures River to host the Wine Desktop (Pure Wayland)

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"

# Path to your compiled WM
RINUX_BIN="$HOME/Rinux/rinux-wm"

# 1. Force Wine to use the native Wayland driver (Registry Tweak)
echo "Enabling Wine Wayland driver..."
wine reg add "HKCU\Software\Wine\Drivers" /v Graphics /t REG_SZ /d "wayland" /f

echo "Generating River init file..."

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Start your custom Window Manager in the background
$RINUX_BIN &

# 2. Keybindings (Minimalist)
riverctl map normal Super Q close
riverctl map normal Super Return spawn foot
riverctl map normal Super E exit

# 3. Window Rules for Wine
# Ensure Wine doesn't get tiled or decorated with Linux title bars
riverctl rule-add -app-id "wine*" float
riverctl csd-filter-add "wine*"

# 4. Launch Wine Desktop
# Adding 'explorer.exe' at the end specifically tells Wine to start the taskbar shell
wine explorer /desktop=Rinux,1280x800 explorer.exe &

# 5. Set background color (Steel Blue)
riverctl background-color 0x4682b4
EOF

chmod +x "$CONFIG_DIR/init"
echo "---"
echo "Config complete. Run 'river' to start your Pure Wayland Wine DE."