#!/bin/sh
# config.sh - Optimized for Wine 10 + Wayland Driver

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"
TERM_CMD="foot"

RES_W=1280
RES_H=800

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Force Wine 10 to use Wayland by unsetting DISPLAY
# 2. Disable DXVK/VKD3D and force GDI for stability in your tools
unset DISPLAY
export WINEDEBUG=-all
export WINE_VIDEO_UPPER_BOUNDS=0 # Helps some apps avoid DXVK hooks
export RENDERER=gdi 

# 3. Start your C++ WM Host
$RINUX_BIN &

# 4. Give the compositor a moment to breathe
sleep 0.5

# 5. Native River Rules
riverctl default-border-width 2
riverctl background-color 0x002b36
riverctl map normal Super Return spawn $TERM_CMD
riverctl map normal Super E exit

# 6. The "Smoke and Mirrors" Desktop
# Using 'env -u' as a double-safety to ensure DISPLAY is gone for this process
env -u DISPLAY wine explorer /desktop=Rinux,${RES_W}x${RES_H} > /tmp/rinux-boot.log 2>&1 &

EOF

chmod +x "$CONFIG_DIR/init"