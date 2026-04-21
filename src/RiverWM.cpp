#include "../include/RiverWM.hpp"
#include <cstring>

// --- Registry Listeners ---
static void registry_global(void* data, wl_registry* reg, uint32_t name, const char* intf, uint32_t ver) {
    static_cast<RiverWM*>(data)->handle_global(reg, name, intf, ver);
}
static void registry_global_remove(void* data, wl_registry* reg, uint32_t name) {}

static const wl_registry_listener registry_listener = {
    registry_global,
    registry_global_remove
};

// --- Window Manager Callbacks ---

// unavailable: 2 args (data, resource)
static void wm_unavailable(void* data, river_window_manager_v1* wm) {
    static_cast<RiverWM*>(data)->handle_unavailable();
}

// window: 3 args (data, resource, new_id)
static void wm_window(void* data, river_window_manager_v1* wm, river_window_v1* window) {
    static_cast<RiverWM*>(data)->handle_window(window);
}

// output: 3 args (data, resource, new_id)
static void wm_output(void* data, river_window_manager_v1* wm, river_output_v1* output) {
    static_cast<RiverWM*>(data)->handle_output(output);
}

// seat: 3 args (data, resource, new_id)
static void wm_seat(void* data, river_window_manager_v1* wm, river_seat_v1* seat) {
    static_cast<RiverWM*>(data)->handle_seat(seat);
}

/**
 * THE FIXED LISTENER
 * We use designated initializers to ensure functions map to the correct protocol slots.
 */
static const river_window_manager_v1_listener wm_listener = {
    .unavailable = wm_unavailable,
    .window      = wm_window,
    .output      = wm_output,
    .seat        = wm_seat
};

RiverWM::RiverWM() {}

RiverWM::~RiverWM() {
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
        river_wm = static_cast<river_window_manager_v1*>(
            wl_registry_bind(reg, name, &river_window_manager_v1_interface, 1)
        );
    }
}

void RiverWM::handle_window(river_window_v1* window) {
    std::cout << "New window detected!" << std::endl;
    views.push_back(new View{window});
    
    // Basic window setup
    river_window_v1_set_dimension_bounds(window, 800, 600);
}

void RiverWM::handle_output(river_output_v1* output) {
    std::cout << "New output detected!" << std::endl;
}

void RiverWM::handle_seat(river_seat_v1* seat) {
    std::cout << "New seat (input device group) detected!" << std::endl;
}

void RiverWM::handle_unavailable() {
    std::cerr << "River window management protocol is no longer available!" << std::endl;
}

void RiverWM::run() {
    std::cout << "Rinux WM active..." << std::endl;
    while (wl_display_dispatch(display) != -1) {}
}