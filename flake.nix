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
          zig_0_13
          pkg-config
          wayland-scanner
          scdoc
          gcc # Added for your C++ WM logic
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
        
        shellHook = ''
          echo "--- Rinux Development Environment Loaded ---"
          echo "Zig: $(zig version)"
          echo "Compiling against wlroots 0.18"
        '';
      };
    };
}