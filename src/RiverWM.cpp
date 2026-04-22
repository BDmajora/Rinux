#include "../include/RiverWM.hpp"
#include <cstring>
#include <algorithm>
#include <iostream>
#include <cstdlib>

// --- Wayland Output Listeners ---
static void output_geometry(void* data, wl_output* out, int32_t x, int32_t y, int32_t pw, int32_t ph, int32_t sub, const char* make, const char* model, int32_t trans) {}
static void output_done(void* data, wl_output* out) {}
static void output_scale(void* data, wl_output* out, int32_t factor) {}

static void output_mode(void* data, wl_output* out, uint32_t flags, int32_t width, int32_t height, int32_t refresh) {
    if (flags & WL_OUTPUT_MODE_CURRENT) {
        static_cast<RiverWM*>(data)->set_resolution(width, height);
    }
}

static const wl_output_listener output_listener = {
    output_geometry, output_mode, output_done, output_scale
};

// --- Registry Listeners ---
static void registry_global(void* data, wl_registry* reg, uint32_t name, const char* intf, uint32_t ver) {
    static_cast<RiverWM*>(data)->handle_global(reg, name, intf, ver);
}
static void registry_global_remove(void* data, wl_registry* reg, uint32_t name) {}

static const wl_registry_listener registry_listener = {
    registry_global, registry_global_remove
};

// --- Window Manager Callbacks ---
static void wm_unavailable(void* data, river_window_manager_v1* wm) {
    static_cast<RiverWM*>(data)->handle_unavailable();
}

static void wm_manage_start(void* data, river_window_manager_v1* wm) {
    static_cast<RiverWM*>(data)->handle_manage_start();
}

static void wm_render_start(void* data, river_window_manager_v1* wm) {
    static_cast<RiverWM*>(data)->handle_render_start();
}

static void wm_window(void* data, river_window_manager_v1* wm, river_window_v1* window) {
    static_cast<RiverWM*>(data)->handle_window(window);
}

static void wm_output(void* data, river_window_manager_v1* wm, river_output_v1* output) {
    static_cast<RiverWM*>(data)->handle_output(output);
}

static void wm_seat(void* data, river_window_manager_v1* wm, river_seat_v1* seat) {
    static_cast<RiverWM*>(data)->handle_seat(seat);
}

static const river_window_manager_v1_listener wm_listener = {
    .unavailable = wm_unavailable,
    .finished    = nullptr,
    .manage_start = wm_manage_start,
    .render_start = wm_render_start,
    .session_locked = nullptr,
    .session_unlocked = nullptr,
    .window      = wm_window,
    .output      = wm_output,
    .seat        = wm_seat
};

RiverWM::RiverWM() {}

RiverWM::~RiverWM() {
    for (auto v : views) {
        river_node_v1_destroy(v->node);
        river_window_v1_destroy(v->handle);
        delete v;
    }
    if (river_wm) river_window_manager_v1_destroy(river_wm);
    if (registry) wl_registry_destroy(registry);
    if (display) wl_display_disconnect(display);
}

bool RiverWM::connect() {
    display = wl_display_connect(nullptr);
    if (!display) return false;

    registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, this);
    wl_display_roundtrip(display);

    if (!river_wm) return false;
    river_window_manager_v1_add_listener(river_wm, &wm_listener, this);
    return true;
}

void RiverWM::handle_global(wl_registry* reg, uint32_t name, const char* intf, uint32_t ver) {
    if (std::strcmp(intf, "river_window_manager_v1") == 0) {
        river_wm = static_cast<river_window_manager_v1*>(wl_registry_bind(reg, name, &river_window_manager_v1_interface, 1));
    } else if (std::strcmp(intf, "wl_output") == 0) {
        wl_output* output = static_cast<wl_output*>(wl_registry_bind(reg, name, &wl_output_interface, 2));
        wl_output_add_listener(output, &output_listener, this);
    }
}

void RiverWM::set_resolution(int w, int h) {
    screen_width = w;
    screen_height = h;
    if (river_wm) river_window_manager_v1_manage_dirty(river_wm);
}

void RiverWM::handle_window(river_window_v1* window) {
    View* v = new View{window, river_window_v1_get_node(window)};
    views.push_back(v);
    
    if (river_wm) river_window_manager_v1_manage_dirty(river_wm);
}

void RiverWM::handle_output(river_output_v1* output) {
    outputs.push_back(output);
}

void RiverWM::handle_manage_start() {
    layout();
    river_window_manager_v1_manage_finish(river_wm);
}

void RiverWM::handle_render_start() {
    river_window_manager_v1_render_finish(river_wm);
}

void RiverWM::layout() {
    if (views.empty() || outputs.empty()) return;

    for (auto const& v : views) {
        // 1. Assign to output and set size in one call.
        // This is the most reliable "Monocle" method in this protocol version.
        river_window_v1_fullscreen(v->handle, outputs[0]);
        
        // 2. Set node position (0,0 relative to the output)
        river_node_v1_set_position(v->node, 0, 0);

        // 3. Make visible
        river_window_v1_show(v->handle);
    }
}

void RiverWM::handle_seat(river_seat_v1* seat) {}
void RiverWM::handle_unavailable() { std::exit(0); }

void RiverWM::run() {
    std::cout << "[Rinux] Active in Monocle Mode..." << std::endl;
    while (wl_display_dispatch(display) != -1) {}
}