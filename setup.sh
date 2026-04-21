#!/bin/bash
set -e

# --- 1. System Prep & Repository Setup ---
echo "--- 1. Adding River Repository & Installing Base Tools ---"
sudo apt update
sudo apt install -y curl git build-essential xdg-utils wget

# Install repository GPG key
sudo wget -O /usr/share/keyrings/nickh-archive-keyring.gpg https://www.ne.jp/asahi/nickh/debian/nickh-archive-keyring.gpg

# Add repository source
sudo wget -O /etc/apt/sources.list.d/nickh.sources https://www.ne.jp/asahi/nickh/debian/nickh.sources

# --- 2. Install River ---
echo "--- 2. Installing River ---"
sudo apt update
sudo apt install -y river

# --- 3. Configuration ---
echo "--- 3. Setting up River Configuration ---"
mkdir -p ~/.config/river

# Extract example init file
if [ ! -f ~/.config/river/init ]; then
    zcat /usr/share/doc/river/example/init.gz > ~/.config/river/init
    chmod +x ~/.config/river/init
fi

# --- 4. Scaffolding (Rinux Project) ---
echo "--- 4. Setting up Rinux Project Structure ---"
mkdir -p ~/Rinux
cd ~/Rinux

mkdir -p protocol src include

# Download protocol definitions
if [ ! -f "protocol/river-window-management-v1.xml" ]; then
    wget -q https://raw.githubusercontent.com/riverwm/river/master/protocol/river-window-management-v1.xml \
         -O protocol/river-window-management-v1.xml
fi

echo "--- SUCCESS: River installed and Rinux Workspace Ready ---"