#!/bin/bash
# config.sh - Fullscreen Native OS Configuration

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"

echo "Generating River init file..."

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Start Rinux-WM C++ Host
$RINUX_BIN &

# 2. Configure Wine for Full Shell Mode
wine reg add "HKCU\\Software\\Wine\\Drivers" /v Graphics /t REG_SZ /d "wayland,x11" /f
wine reg add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon" /v "Shell" /t REG_SZ /d "explorer.exe" /f

# 3. Native OS River Rules
riverctl default-border-width 0
riverctl csd-filter-add "wine*"

# MUST BE FLOAT: The C++ code forces the desktop to screen size.
# Floating allows the taskbar to sit on top of that desktop without being stretched.
riverctl rule-add -app-id "wine*" float

# 4. Keybindings
riverctl map normal Super Q close
riverctl map normal Super Return spawn foot
riverctl map normal Super E exit

# 5. Launch the Wine Environment
env DISPLAY= wine explorer /desktop=Rinux,1280x800 &

riverctl background-color 0x000000
EOF

chmod +x "$CONFIG_DIR/init"
echo "---"
echo "Config complete. Run 'river' for the Fullscreen Native experience."