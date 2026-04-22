#!/bin/sh
# config.sh - Final "Broken Pipe" Fix for Wine 11

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"
TERM_CMD="foot"

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Start WM and pipe logs to a file so we can see crashes
$RINUX_BIN > /tmp/rinux.log 2>&1 &

# 2. WAIT. Let the EGL/Mesa errors clear and the socket stabilize.
sleep 3

# 3. Basic River Config
riverctl default-border-width 0
riverctl map normal Super Return spawn $TERM_CMD
riverctl map normal Super E exit

# 4. The "Wine 11 Wayland" Autoboot
# We unset DISPLAY specifically for Wine and use the native driver.
# Using 'riverctl spawn' ensures the compositor is the one initiating the process.
riverctl spawn "env -u DISPLAY WINEWAYLAND=1 RENDERER=gdi wine explorer /desktop=Rinux,1280x800"

EOF

chmod +x "$CONFIG_DIR/init"