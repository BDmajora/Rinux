#!/bin/bash
set -e

# --- 1. System Prep ---
echo "--- 1. Updating Debian 13 & Installing Base Tools ---"
sudo apt update
sudo apt install -y curl git build-essential xdg-utils

# --- 2. Nix Installation (The Dependency Engine) ---
if ! command -v nix &> /dev/null; then
    echo "--- 2. Installing Nix ---"
    curl -L https://nixos.org/nix/install | sh -s -- --daemon
    # Load Nix into the current shell session
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
fi

# --- 3. Create the Build Flake ---
# This ensures Zig 0.13+ and wlroots 0.18+ are always used, regardless of Debian repos.
echo "--- 3. Generating Build Environment ---"
cat <<EOF > flake.nix
{
  description = "Rinux-WM Build Environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          zig_0_13
          pkg-config
          wayland-scanner
          scdoc
        ];
        buildInputs = with pkgs; [
          wlroots_0_18
          wayland
          wayland-protocols
          libxkbcommon
          pixman
          libinput
          libcap
          mesa
        ];
      };
    };
}
EOF

# --- 4. Build River inside the Nix Shell ---
echo "--- 4. Building River (Compositor Base) ---"
nix develop --command bash -c "
    if [ ! -d 'river' ]; then
        git clone --recursive https://github.com/riverwm/river
    fi
    cd river
    zig build -Doptimize=ReleaseSafe
    
    echo 'Installing River to /usr/local/bin...'
    sudo cp zig-out/bin/river /usr/local/bin/
    sudo cp zig-out/bin/riverctl /usr/local/bin/
"

# --- 5. Rinux-WM Prep ---
echo "--- 5. Preparing Rinux-WM Protocol & Headers ---"
mkdir -p protocol src include

# We get the protocol directly to your project folder, not /usr/share
wget -q https://raw.githubusercontent.com/riverwm/river/master/protocol/river-window-management-v1.xml \
     -O protocol/river-window-management-v1.xml

echo "--- SUCCESS: Environment Ready ---"
echo "To build your custom WM, use: 'nix develop --command zig build'"