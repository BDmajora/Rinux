#!/bin/bash

# Generate protocol files
echo "Generating Wayland protocols..."
wayland-scanner client-header protocol/river-window-management-v1.xml src/river-window-management-v1-client-protocol.h

# Use private-code instead of public-code to avoid visibility warnings
wayland-scanner private-code protocol/river-window-management-v1.xml src/river-window-management-v1-client-protocol.c

# Compile the C protocol file separately using gcc to preserve C linkage
echo "Compiling Wayland protocol (C)..."
gcc -c -fPIC src/river-window-management-v1-client-protocol.c -o src/river-window-management-v1-client-protocol.o

# Compile the C++ files and link the compiled C object
echo "Compiling Rinux (C++)..."
g++ -std=c++17 -Wall -fPIC -I./include -I./src \
    src/main.cpp \
    src/RiverWM.cpp \
    src/river-window-management-v1-client-protocol.o \
    -o rinux-wm \
    -lwayland-client

if [ $? -eq 0 ]; then
    echo "Success: ./rinux-wm"
else
    echo "Build failed."
fi