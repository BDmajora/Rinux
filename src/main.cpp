#include "../include/RiverWM.hpp"
#include <cstdlib>
#include <iostream>

int main(int argc, char* argv[]) {
    // Diagnose environment before attempting connection
    const char* wayland = getenv("WAYLAND_DISPLAY");
    const char* xdg     = getenv("XDG_RUNTIME_DIR");

    std::cerr << "[Rinux] WAYLAND_DISPLAY=" << (wayland ? wayland : "NOT SET") << "\n";
    std::cerr << "[Rinux] XDG_RUNTIME_DIR=" << (xdg     ? xdg     : "NOT SET") << "\n";

    RiverWM wm;

    if (!wm.connect()) {
        std::cerr << "[Rinux] connect() failed.\n";
        std::cerr << "[Rinux] Possible causes:\n";
        std::cerr << "  1. WAYLAND_DISPLAY is not set or wrong\n";
        std::cerr << "  2. river_window_manager_v1 not advertised (River not running or another WM is bound)\n";
        std::cerr << "  3. XDG_RUNTIME_DIR does not contain the Wayland socket\n";
        return 1;
    }

    wm.run();
    return 0;
}