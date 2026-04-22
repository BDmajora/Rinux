#!/bin/sh
# config.sh - Wine Wayland Shell Initialization

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# Start layout generator to prevent 0x0 window dimensions
rivertile -view-padding 0 -outer-padding 0 &
riverctl default-layout rivertile

# Launch C++ Host
$RINUX_BIN &

# Registry: Enable Wayland Driver
wine reg add "HKCU\\Software\\Wine\\Drivers" /v Graphics /t REG_SZ /d "wayland" /f

# Registry: Set Internal Explorer as Shell
wine reg add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon" /v "Shell" /t REG_SZ /d "explorer.exe" /f

# Registry: Define Virtual Desktop Dimensions
wine reg add "HKCU\\Software\\Wine\\Explorer" /v "Desktop" /t REG_SZ /d "Rinux" /f
wine reg add "HKCU\\Software\\Wine\\Explorer\\Desktops" /v "Rinux" /t REG_SZ /d "1280x800" /f

# River Rules
riverctl default-border-width 0
riverctl rule-add -app-id "org.winehq.wine" float
riverctl rule-add -title "Wine Desktop" float

# Keybindings
riverctl map normal Super Q close
riverctl map normal Super E exit

# Launch Wine Explorer with explicit desktop geometry
unset DISPLAY
env WAYLAND_DISPLAY=\$WAYLAND_DISPLAY wine explorer /desktop=Rinux,1280x800 &

riverctl background-color 0x000000
EOF

chmod +x "$CONFIG_DIR/init"
echo "Registry configured. Shell enabled."