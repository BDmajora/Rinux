#!/bin/bash
# setup.sh - The "Lazy Dev" Bootstrap for Rinux

# Exit on error
set -e

echo "--- Initializing Rinux Environment ---"

# 1. Update and install core dependencies
sudo apt update
sudo apt install -y build-essential libwayland-dev libwayland-bin \
                    wayland-protocols pkg-config river wget git

# 2. Setup directory structure
mkdir -p protocol include src

# 3. Fetch the required River protocol XML
if [ ! -f protocol/river-window-management-v1.xml ]; then
    echo "Downloading River protocol..."
    wget https://codeberg.org/river/river/raw/branch/master/protocol/river-window-management-v1.xml \
         -O protocol/river-window-management-v1.xml
fi

# 4. Ensure build.sh is executable
if [ -f build.sh ]; then
    chmod +x build.sh
    echo "Setup complete. Running build..."
    ./build.sh
else
    echo "Setup complete. (No build.sh found to run automatically)"
fi