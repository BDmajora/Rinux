#!/bin/sh
# config.sh - Using riverctl spawn for Wine 11 Autoboot

CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"
TERM_CMD="foot"

RES_W=1280
RES_H=800

cat <<EOF > "$CONFIG_DIR/init"
#!/bin/sh

# 1. Start your C++ WM Host
$RINUX_BIN > /tmp/rinux-wm.log 2>&1 &

# 2. Wait for River/Rinux to settle
sleep 1.5

# 3. Native River Rules
riverctl default-border-width 0
riverctl map normal Super Return spawn $TERM_CMD
riverctl map normal Super E exit

# 4. Autoboot the Desktop via riverctl spawn!
# This forces River to launch it just like it would if you pressed a keybind
riverctl spawn "env -u DISPLAY WINEWAYLAND=1 RENDERER=gdi wine explorer /desktop=Rinux,${RES_W}x${RES_H}"

EOF

chmod +x "$CONFIG_DIR/init"