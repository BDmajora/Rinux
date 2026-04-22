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

# 2. Force Native Wayland Driver & Reset Shell
# We explicitly set 'wayland' and purge any 'x11' fallback.
wine reg add "HKCU\\Software\\Wine\\Drivers" /v Graphics /t REG_SZ /d "wayland" /f
wine reg add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon" /v "Shell" /t REG_SZ /d "explorer.exe" /f

# 3. Native OS River Rules
# River is confirmed working
riverctl default-border-width 0
riverctl csd-filter-add "wine*"
riverctl rule-add -app-id "wine-explorer" float

# 4. Keybindings
riverctl map normal Super Q close
riverctl map normal Super Return spawn foot
riverctl map normal Super E exit

# 5. Launch the Wine Environment
# We UNSET DISPLAY to ensure no XWayland accidental fallback.
# We pass ONLY the desktop dimensions. 
# In Wine 11, this triggers the internal Shell process automatically
# if the registry 'Shell' key is valid.
unset DISPLAY
env WAYLAND_DISPLAY=\$WAYLAND_DISPLAY wine explorer /desktop=Rinux,1280x800 &

riverctl background-color 0x000000
EOF

chmod +x "$CONFIG_DIR/init"
echo "---"
echo "Pure Wayland config complete. Start 'river' to test."