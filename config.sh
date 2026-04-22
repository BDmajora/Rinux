#!/bin/sh
# config.sh - Pure Wayland Wine Shell Configuration

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"

echo "Generating River init file..."

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Start Rinux-WM C++ Host
$RINUX_BIN &

# 2. Force Native Wayland Driver
wine reg add "HKCU\\Software\\Wine\\Drivers" /v Graphics /t REG_SZ /d "wayland" /f

# 3. SET VIRTUAL DESKTOP VIA REGISTRY (No winecfg needed)
# This enables the 'Emulate a virtual desktop' feature and sets the size.
wine reg add "HKCU\\Software\\Wine\\Explorer" /v "Desktop" /t REG_SZ /d "Rinux" /f
wine reg add "HKCU\\Software\\Wine\\Explorer\\Desktops" /v "Rinux" /t REG_SZ /d "1280x800" /f

# 4. Ensure the Shell is set to internal explorer
wine reg add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon" /v "Shell" /t REG_SZ /d "explorer.exe" /f

# 5. Native OS River Rules
riverctl default-border-width 0
riverctl csd-filter-add "wine*"
riverctl rule-add -app-id "wine-explorer" float

# 6. Keybindings
riverctl map normal Super Q close
riverctl map normal Super Return spawn foot
riverctl map normal Super E exit

# 7. Launch the Wine Environment
# Since we enabled the virtual desktop in the registry (Stage 3), 
# we no longer need the '/desktop' flag in the command. 
# We just launch explorer.exe and it will use the registry settings.
unset DISPLAY
env WAYLAND_DISPLAY=\$WAYLAND_DISPLAY wine explorer /desktop=Rinux &

riverctl background-color 0x000000
EOF

chmod +x "$CONFIG_DIR/init"
echo "---"
echo "Registry-based Wayland config complete."