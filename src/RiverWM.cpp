#include "../include/RiverWM.hpp"
#include <cstring>

static void registry_global(void* data, wl_registry* reg, uint32_t name, const char* intf, uint32_t ver) {
    static_cast<RiverWM*>(data)->handle_global(reg, name, intf, ver);
}
static void registry_global_remove(void* data, wl_registry* reg, uint32_t name) {}

static const wl_registry_listener registry_listener = {
    registry_global,
    registry_global_remove
};

static void wm_manage_start(void* data, river_window_manager_v1* wm) {
    static_cast<RiverWM*>(data)->handle_manage_start();
}
static void wm_render_start(void* data, river_window_manager_v1* wm) {
    static_cast<RiverWM*>(data)->handle_render_start();
}
static void wm_manage_finish(void* data, river_window_manager_v1* wm) {}
static void wm_render_finish(void* data, river_window_manager_v1* wm) {}

static const river_window_manager_v1_listener wm_listener = {
    wm_manage_start,
    wm_manage_finish,
    wm_render_start,
    wm_render_finish
};

RiverWM::RiverWM() {}

RiverWM::~RiverWM() {
    if (river_wm) river_window_manager_v1_destroy(river_wm);
    if (registry) wl_registry_destroy(registry);
    if (display) wl_display_disconnect(display);
}

bool RiverWM::connect() {
    display = wl_display_connect(nullptr);
    if (!display) {
        std::cerr << "Failed to connect to Wayland display." << std::endl;
        return false;
    }

    registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, this);
    wl_display_roundtrip(display);

    if (!river_wm) {
        std::cerr << "River protocol not found. Is River running?" << std::endl;
        return false;
    }

    river_window_manager_v1_add_listener(river_wm, &wm_listener, this);
    return true;
}

void RiverWM::handle_global(wl_registry* reg, uint32_t name, const char* intf, uint32_t ver) {
    if (std::strcmp(intf, "river_window_manager_v1") == 0) {
        river_wm = static_cast<river_window_manager_v1*>(
            wl_registry_bind(reg, name, &river_window_manager_v1_interface, 1)
        );
    }
}

void RiverWM::handle_manage_start() {}

void RiverWM::handle_render_start() {
    river_window_manager_v1_render_finish(river_wm);
}

void RiverWM::run() {
    std::cout << "Rinux WM active..." << std::endl;
    while (wl_display_dispatch(display) != -1) {}
}