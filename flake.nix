{
  description = "Rinux-WM Build Environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          zig # Updated to 0.14+ to match River source
          pkg-config
          wayland-scanner
          scdoc
          gcc
        ];
        buildInputs = with pkgs; [
          wlroots_0_18
          wayland
          wayland-protocols
          libxkbcommon
          pixman
          libinput
          libevdev.dev
          libcap
          mesa
          libglvnd
          libusb1 # Added for your USB Bridge project
        ];
        
        shellHook = ''
          echo "--- Rinux Development Environment Loaded ---"
          echo "Zig: $(zig version)"
          echo "Compiling against wlroots 0.18"
        '';
      };
    };
}