#!/bin/bash
set -e

# 1. install system dependencies
sudo apt update
sudo apt install -y curl git build-essential xdg-utils wget

# 2. setup nickh repository for river
# official debian 13 repos lack river; using the unofficial bookworm repo
sudo wget -O /usr/share/keyrings/nickh-archive-keyring.gpg https://www.ne.jp/asahi/nickh/debian/nickh-archive-keyring.gpg
sudo wget -O /etc/apt/sources.list.d/nickh.sources https://www.ne.jp/asahi/nickh/debian/nickh.sources

# 3. sync and install river
sudo apt update
sudo apt install -y river

# 4. setup river configuration
mkdir -p ~/.config/river
if [ ! -f ~/.config/river/init ]; then
    zcat /usr/share/doc/river/example/init.gz > ~/.config/river/init
    chmod +x ~/.config/river/init
fi

# 5. prepare rinux workspace
mkdir -p ~/Rinux
cd ~/Rinux
mkdir -p protocol src include

# fetch window management protocol
if [ ! -f "protocol/river-window-management-v1.xml" ]; then
    wget -q https://raw.githubusercontent.com/riverwm/river/master/protocol/river-window-management-v1.xml \
         -O protocol/river-window-management-v1.xml
fi

echo "setup complete: river installed via nickh repo"