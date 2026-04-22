#!/bin/bash
set -e

# 1. Setup paths
PROTO_DIR="protocol"
SRC_DIR="src"
mkdir -p $PROTO_DIR $SRC_DIR

# 2. Path to your river clone
RIVER_REPO_PATH="../river"

echo "Copying ONLY confirmed protocol files..."
# These two are the heavy hitters for a WM
cp "$RIVER_REPO_PATH/protocol/river-window-management-v1.xml" $PROTO_DIR/
cp "$RIVER_REPO_PATH/protocol/river-input-management-v1.xml" $PROTO_DIR/

# 3. Generate Headers for confirmed files
echo "Running wayland-scanner..."
wayland-scanner client-header $PROTO_DIR/river-window-management-v1.xml $SRC_DIR/river-window-management-v1-client-protocol.h
wayland-scanner private-code $PROTO_DIR/river-window-management-v1.xml $SRC_DIR/river-window-management-v1-client-protocol.c

wayland-scanner client-header $PROTO_DIR/river-input-management-v1.xml $SRC_DIR/river-input-management-v1-client-protocol.h
wayland-scanner private-code $PROTO_DIR/river-input-management-v1.xml $SRC_DIR/river-input-management-v1-client-protocol.c

# 4. Compile Protocol Objects
echo "Compiling C objects..."
gcc -c -fPIC $SRC_DIR/river-window-management-v1-client-protocol.c -o $SRC_DIR/river-window-management-v1.o
gcc -c -fPIC $SRC_DIR/river-input-management-v1-client-protocol.c -o $SRC_DIR/river-input-management-v1.o

# 5. Build Rinux-WM
echo "Compiling Rinux-WM..."
# We only link the objects we actually generated
g++ -std=c++17 -Wall -fPIC -I./include -I./src \
    src/main.cpp \
    src/RiverWM.cpp \
    $SRC_DIR/river-window-management-v1.o \
    $SRC_DIR/river-input-management-v1.o \
    -o rinux-wm \
    -lwayland-client

echo "-----------------------------------------------"
echo "Build complete using confirmed 0.4.x protocols."