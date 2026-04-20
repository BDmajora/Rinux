#ifndef RIVER_WM_HPP
#define RIVER_WM_HPP

#include <wayland-client.h>

extern "C" {
#include "river-window-management-v1-client-protocol.h"
}

#include <vector>
#include <iostream>

class RiverWM {
public:
    RiverWM();
    ~RiverWM();

    bool connect();
    void run();

    void handle_global(wl_registry* registry, uint32_t name, const char* interface, uint32_t version);
    void handle_manage_start();
    void handle_render_start();

private:
    wl_display* display = nullptr;
    wl_registry* registry = nullptr;
    river_window_manager_v1* river_wm = nullptr;

    struct View {
        river_window_v1* handle;
    };
    std::vector<View*> views;
};

#endif