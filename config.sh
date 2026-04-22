#!/bin/sh
CONFIG_DIR="$HOME/.config/river"
mkdir -p "$CONFIG_DIR"
RINUX_BIN="$HOME/Rinux/rinux-wm"
TERM_CMD="foot"

cat <<'RIVERINIT' > "$CONFIG_DIR/init"
#!/bin/sh

# Ensure Wayland environment is available to all child processes.
# River sets these but child shells spawned later may not inherit them.
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# 1. Start Rinux WM Host
# Must be launched AFTER the env vars above are exported.
$HOME/Rinux/rinux-wm > /tmp/rinux.log 2>&1 &

# 2. Wait for rinux-wm to bind as window manager
sleep 2

# 3. Keybindings
riverctl default-border-width 0
# Pass env vars explicitly into the spawned terminal so it inherits them
riverctl map normal Super Return spawn "env WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR foot"
riverctl map normal Super E exit

# 4. Let Wine draw its own decorations — do NOT float (float bypasses the WM)
riverctl csd-filter-add "wine_explorer.exe"
riverctl csd-filter-add "wine*"

# 5. Background
riverctl background-color 0x4682b4

# 6. Launch Wine Desktop
riverctl spawn "env -u DISPLAY WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR WINEWAYLAND=1 wine explorer /desktop=shell,1280x800"
RIVERINIT

chmod +x "$CONFIG_DIR/init"
echo "Rinux Desktop Configured. Restart River to boot into Wine."