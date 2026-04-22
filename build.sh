#!/bin/bash
set -e

# 1. Setup paths
PROTO_DIR="protocol"
SRC_DIR="src"
mkdir -p "$PROTO_DIR" "$SRC_DIR"

# 2. Get Protocol Files (The Smart Way)
# Check if they already exist in the protocol folder first.
if [ -f "$PROTO_DIR/river-window-management-v1.xml" ] && [ -f "$PROTO_DIR/river-input-management-v1.xml" ]; then
    echo "[Rinux] Protocols already exist in ./$PROTO_DIR. Skipping fetch."
else
    # If not in ./protocol, check for local repo
    if [ -d "../river/protocol" ]; then
        echo "[Rinux] Protocols missing but found local river repo. Copying..."
        cp "../river/protocol/river-window-management-v1.xml" "$PROTO_DIR/"
        cp "../river/protocol/river-input-management-v1.xml" "$PROTO_DIR/"
    else
        # Nuclear option: curl them
        echo "[Rinux] Protocols missing and no local repo found. Curiling..."
        BASE_URL="https://codeberg.org/river/river/raw/branch/master/protocol"
        curl -L "$BASE_URL/river-window-management-v1.xml" -o "$PROTO_DIR/river-window-management-v1.xml"
        curl -L "$BASE_URL/river-input-management-v1.xml" -o "$PROTO_DIR/river-input-management-v1.xml"
    fi
fi

# 3. Generate Headers and Code
echo "[Rinux] Running wayland-scanner..."
wayland-scanner client-header "$PROTO_DIR/river-window-management-v1.xml" "$SRC_DIR/river-window-management-v1-client-protocol.h"
wayland-scanner private-code "$PROTO_DIR/river-window-management-v1.xml" "$SRC_DIR/river-window-management-v1-client-protocol.c"

wayland-scanner client-header "$PROTO_DIR/river-input-management-v1.xml" "$SRC_DIR/river-input-management-v1-client-protocol.h"
wayland-scanner private-code "$PROTO_DIR/river-input-management-v1.xml" "$SRC_DIR/river-input-management-v1-client-protocol.c"

# 4. Compile Protocol Objects
echo "[Rinux] Compiling C objects..."
gcc -c -fPIC "$SRC_DIR/river-window-management-v1-client-protocol.c" -o "$SRC_DIR/river-window-management-v1.o"
gcc -c -fPIC "$SRC_DIR/river-input-management-v1-client-protocol.c" -o "$SRC_DIR/river-input-management-v1.o"

# 5. Build Rinux-WM
echo "[Rinux] Compiling Rinux-WM binary..."
g++ -std=c++17 -Wall -fPIC -I./include -I./src \
    src/main.cpp \
    src/RiverWM.cpp \
    "$SRC_DIR/river-window-management-v1.o" \
    "$SRC_DIR/river-input-management-v1.o" \
    -o rinux-wm \
    -lwayland-client

echo "-----------------------------------------------"
echo "Build complete. Binary at: ./rinux-wm"