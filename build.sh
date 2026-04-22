#!/bin/bash
set -e

# 1. Setup paths
PROTO_DIR="protocol"
SRC_DIR="src"
mkdir -p $PROTO_DIR $SRC_DIR

# 2. Get Protocol Files
# Fallback: If the local repo doesn't exist, download them from the official source
if [ ! -f "../river/protocol/river-window-management-v1.xml" ]; then
    echo "[Rinux] Local river repo not found. Downloading protocols..."
    wget -q https://codeberg.org/river/river/raw/branch/master/protocol/river-window-management-v1.xml -O $PROTO_DIR/river-window-management-v1.xml
    wget -q https://codeberg.org/river/river/raw/branch/master/protocol/river-input-management-v1.xml -O $PROTO_DIR/river-input-management-v1.xml
else
    echo "[Rinux] Copying protocols from local repo..."
    cp "../river/protocol/river-window-management-v1.xml" $PROTO_DIR/
    cp "../river/protocol/river-input-management-v1.xml" $PROTO_DIR/
fi

# 3. Generate Headers
echo "[Rinux] Running wayland-scanner..."
wayland-scanner client-header $PROTO_DIR/river-window-management-v1.xml $SRC_DIR/river-window-management-v1-client-protocol.h
wayland-scanner private-code $PROTO_DIR/river-window-management-v1.xml $SRC_DIR/river-window-management-v1-client-protocol.c

wayland-scanner client-header $PROTO_DIR/river-input-management-v1.xml $SRC_DIR/river-input-management-v1-client-protocol.h
wayland-scanner private-code $PROTO_DIR/river-input-management-v1.xml $SRC_DIR/river-input-management-v1-client-protocol.c

# 4. Compile Protocol Objects
echo "[Rinux] Compiling C objects..."
gcc -c -fPIC $SRC_DIR/river-window-management-v1-client-protocol.c -o $SRC_DIR/river-window-management-v1.o
gcc -c -fPIC $SRC_DIR/river-input-management-v1-client-protocol.c -o $SRC_DIR/river-input-management-v1.o

# 5. Build Rinux-WM
echo "[Rinux] Compiling Rinux-WM binary..."
g++ -std=c++17 -Wall -fPIC -I./include -I./src \
    src/main.cpp \
    src/RiverWM.cpp \
    $SRC_DIR/river-window-management-v1.o \
    $SRC_DIR/river-input-management-v1.o \
    -o rinux-wm \
    -lwayland-client

echo "-----------------------------------------------"
echo "Build complete. Run ./rinux-wm or use your init script."