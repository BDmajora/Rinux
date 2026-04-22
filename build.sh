#!/bin/bash
set -e

PROTO_DIR="protocol"
SRC_DIR="src"

# 1. Strict existence check
if [ ! -s "$PROTO_DIR/river-window-management-v1.xml" ] || [ ! -s "$PROTO_DIR/river-input-management-v1.xml" ]; then
    echo "[Rinux] ERROR: Protocols in $PROTO_DIR/ are empty or missing."
    echo "Check file size: $(ls -lh $PROTO_DIR/)"
    exit 1
fi

echo "[Rinux] Using existing protocols. Running wayland-scanner..."

# 2. Generate Headers and Code
wayland-scanner client-header "$PROTO_DIR/river-window-management-v1.xml" "$SRC_DIR/river-window-management-v1-client-protocol.h"
wayland-scanner private-code "$PROTO_DIR/river-window-management-v1.xml" "$SRC_DIR/river-window-management-v1-client-protocol.c"

wayland-scanner client-header "$PROTO_DIR/river-input-management-v1.xml" "$SRC_DIR/river-input-management-v1-client-protocol.h"
wayland-scanner private-code "$PROTO_DIR/river-input-management-v1.xml" "$SRC_DIR/river-input-management-v1-client-protocol.c"

# 3. Compile Protocol Objects
echo "[Rinux] Compiling C objects..."
gcc -c -fPIC "$SRC_DIR/river-window-management-v1-client-protocol.c" -o "$SRC_DIR/river-window-management-v1.o"
gcc -c -fPIC "$SRC_DIR/river-input-management-v1-client-protocol.c" -o "$SRC_DIR/river-input-management-v1.o"

# 4. Build Rinux-WM
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