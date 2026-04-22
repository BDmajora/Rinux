#include "../include/RiverWM.hpp"
#include <cstring>
#include <iostream>
#include <cstdlib>
#include <string>

// ---------------------------------------------------------------------------
// river_window_v1 listener
// ---------------------------------------------------------------------------

static void win_closed(void*, river_window_v1*) {}
static void win_dimensions_hint(void*, river_window_v1*, int32_t, int32_t, int32_t, int32_t) {}

// KEY: capture the actual dimensions the compositor gives each window.
// This fires during the render sequence — we store them on the View so
// layout() can use them to tell the taskbar apart from the desktop.
static void win_dimensions(void* data, river_window_v1*, int32_t w, int32_t h) {
    auto* v = static_cast<View*>(data);
    v->width  = w;
    v->height = h;
    std::cerr << "[Rinux] window dimensions: " << w << "x" << h
              << "  app_id='" << v->app_id << "'\n";
}

static void win_app_id(void* data, river_window_v1*, const char* id) {
    if (id) static_cast<View*>(data)->app_id = id;
}
static void win_title(void* data, river_window_v1*, const char* t) {
    if (t) static_cast<View*>(data)->title = t;
}
static void win_parent(void*, river_window_v1*, river_window_v1*) {}
static void win_decoration_hint(void*, river_window_v1*, uint32_t) {}
static void win_pointer_move_requested(void*, river_window_v1*, river_seat_v1*) {}
static void win_pointer_resize_requested(void*, river_window_v1*, river_seat_v1*, uint32_t) {}
static void win_show_window_menu_requested(void*, river_window_v1*, int32_t, int32_t) {}
static void win_maximize_requested(void*, river_window_v1*) {}
static void win_unmaximize_requested(void*, river_window_v1*) {}
static void win_fullscreen_requested(void*, river_window_v1*, river_output_v1*) {}
static void win_exit_fullscreen_requested(void*, river_window_v1*) {}
static void win_minimize_requested(void*, river_window_v1*) {}
static void win_unreliable_pid(void*, river_window_v1*, int32_t) {}
static void win_presentation_hint(void*, river_window_v1*, uint32_t) {}
static void win_identifier(void*, river_window_v1*, const char*) {}

static const river_window_v1_listener window_listener = {
    .closed                     = win_closed,
    .dimensions_hint            = win_dimensions_hint,
    .dimensions                 = win_dimensions,
    .app_id                     = win_app_id,
    .title                      = win_title,
    .parent                     = win_parent,
    .decoration_hint            = win_decoration_hint,
    .pointer_move_requested     = win_pointer_move_requested,
    .pointer_resize_requested   = win_pointer_resize_requested,
    .show_window_menu_requested = win_show_window_menu_requested,
    .maximize_requested         = win_maximize_requested,
    .unmaximize_requested       = win_unmaximize_requested,
    .fullscreen_requested       = win_fullscreen_requested,
    .exit_fullscreen_requested  = win_exit_fullscreen_requested,
    .minimize_requested         = win_minimize_requested,
    .unreliable_pid             = win_unreliable_pid,
    .presentation_hint          = win_presentation_hint,
    .identifier                 = win_identifier,
};

// ---------------------------------------------------------------------------
// river_output_v1 listener
// ---------------------------------------------------------------------------

static void rout_removed(void*, river_output_v1*) {}
static void rout_wl_output(void*, river_output_v1*, uint32_t) {}
static void rout_position(void* data, river_output_v1*, int32_t x, int32_t y) {
    auto* o = static_cast<OutputInfo*>(data);
    o->x = x; o->y = y;
}
static void rout_dimensions(void* data, river_output_v1*, int32_t w, int32_t h) {
    auto* o = static_cast<OutputInfo*>(data);
    o->width = w; o->height = h;
    std::cerr << "[Rinux] output logical dimensions: " << w << "x" << h << "\n";
}
static const river_output_v1_listener rout_listener = {
    .removed    = rout_removed,
    .wl_output  = rout_wl_output,
    .position   = rout_position,
    .dimensions = rout_dimensions,
};

// ---------------------------------------------------------------------------
// wl_output listener (fallback resolution)
// ---------------------------------------------------------------------------

static void output_geometry(void*, wl_output*, int32_t, int32_t, int32_t,
    int32_t, int32_t, const char*, const char*, int32_t) {}
static void output_done(void*, wl_output*) {}
static void output_scale(void*, wl_output*, int32_t) {}
static void output_mode(void* data, wl_output*, uint32_t flags,
    int32_t w, int32_t h, int32_t)
{
    if (flags & WL_OUTPUT_MODE_CURRENT)
        static_cast<RiverWM*>(data)->set_resolution(w, h);
}
static const wl_output_listener output_listener = {
    output_geometry, output_mode, output_done, output_scale
};

// ---------------------------------------------------------------------------
// wl_registry listener
// ---------------------------------------------------------------------------

static void registry_global(void* data, wl_registry* reg,
    uint32_t name, const char* intf, uint32_t ver)
{
    static_cast<RiverWM*>(data)->handle_global(reg, name, intf, ver);
}
static void registry_global_remove(void*, wl_registry*, uint32_t) {}
static const wl_registry_listener registry_listener = {
    registry_global, registry_global_remove
};

// ---------------------------------------------------------------------------
// river_window_manager_v1 listener
// ---------------------------------------------------------------------------

static void wm_unavailable(void* data, river_window_manager_v1*) {
    static_cast<RiverWM*>(data)->handle_unavailable();
}
static void wm_finished(void*, river_window_manager_v1*) {}
static void wm_manage_start(void* data, river_window_manager_v1*) {
    static_cast<RiverWM*>(data)->handle_manage_start();
}
static void wm_render_start(void* data, river_window_manager_v1*) {
    static_cast<RiverWM*>(data)->handle_render_start();
}
static void wm_session_locked(void*, river_window_manager_v1*) {}
static void wm_session_unlocked(void*, river_window_manager_v1*) {}
static void wm_window(void* data, river_window_manager_v1*, river_window_v1* win) {
    static_cast<RiverWM*>(data)->handle_window(win);
}
static void wm_output(void* data, river_window_manager_v1*, river_output_v1* out) {
    static_cast<RiverWM*>(data)->handle_output(out);
}
static void wm_seat(void* data, river_window_manager_v1*, river_seat_v1* seat) {
    static_cast<RiverWM*>(data)->handle_seat(seat);
}
static const river_window_manager_v1_listener wm_listener = {
    .unavailable      = wm_unavailable,
    .finished         = wm_finished,
    .manage_start     = wm_manage_start,
    .render_start     = wm_render_start,
    .session_locked   = wm_session_locked,
    .session_unlocked = wm_session_unlocked,
    .window           = wm_window,
    .output           = wm_output,
    .seat             = wm_seat,
};

// ---------------------------------------------------------------------------
// RiverWM
// ---------------------------------------------------------------------------

RiverWM::RiverWM() {}

RiverWM::~RiverWM() {
    for (auto v : views) {
        river_node_v1_destroy(v->node);
        river_window_v1_destroy(v->handle);
        delete v;
    }
    for (auto o : output_infos) {
        river_output_v1_destroy(o->handle);
        delete o;
    }
    if (river_wm) river_window_manager_v1_destroy(river_wm);
    if (registry) wl_registry_destroy(registry);
    if (display)  wl_display_disconnect(display);
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

void RiverWM::handle_global(wl_registry* reg, uint32_t name,
    const char* intf, uint32_t)
{
    if (std::strcmp(intf, "river_window_manager_v1") == 0) {
        river_wm = static_cast<river_window_manager_v1*>(
            wl_registry_bind(reg, name, &river_window_manager_v1_interface, 1));
    } else if (std::strcmp(intf, "wl_output") == 0) {
        auto* out = static_cast<wl_output*>(
            wl_registry_bind(reg, name, &wl_output_interface, 2));
        wl_output_add_listener(out, &output_listener, this);
    }
}

void RiverWM::set_resolution(int w, int h) {
    screen_width  = w;
    screen_height = h;
    if (river_wm) river_window_manager_v1_manage_dirty(river_wm);
}

void RiverWM::handle_window(river_window_v1* window) {
    View* v   = new View{};
    v->handle = window;
    v->node   = river_window_v1_get_node(window);
    river_window_v1_add_listener(window, &window_listener, v);
    views.push_back(v);
    if (river_wm) river_window_manager_v1_manage_dirty(river_wm);
}

void RiverWM::handle_output(river_output_v1* output) {
    OutputInfo* info = new OutputInfo{};
    info->handle = output;
    river_output_v1_add_listener(output, &rout_listener, info);
    output_infos.push_back(info);
    if (river_wm) river_window_manager_v1_manage_dirty(river_wm);
}

void RiverWM::handle_manage_start() {
    layout();
    river_window_manager_v1_manage_finish(river_wm);
}

void RiverWM::handle_render_start() {
    river_window_manager_v1_render_finish(river_wm);
}

void RiverWM::layout() {
    if (views.empty() || output_infos.empty()) return;

    OutputInfo* primary = output_infos[0];
    int out_w = (primary->width  > 0) ? primary->width  : screen_width;
    int out_h = (primary->height > 0) ? primary->height : screen_height;

    // ---------------------------------------------------------------------------
    // Identify the taskbar by its dimensions rather than app_id.
    //
    // The app_id event arrives asynchronously and is often empty on the first
    // manage_start. Instead we use the actual window height:
    //   - Wine taskbar:       height is small (Wine default = 30px, never > 100)
    //   - Wine desktop shell: height equals or exceeds the output height
    //
    // On the very first cycle, dimensions may be 0 (not yet received). In that
    // case we fall back to app_id matching so the initial show still works.
    // ---------------------------------------------------------------------------

    for (auto v : views) {
        bool is_taskbar = false;

        if (v->height > 0 && v->height < 100) {
            // Dimensions received and clearly a panel-sized window
            is_taskbar = true;
        } else if (v->height == 0) {
            // Dimensions not received yet — use app_id as early hint
            is_taskbar = (v->app_id.find("explorer") != std::string::npos);
        }

        if (is_taskbar) {
            // Tell Wine the taskbar should be full-width, 30px tall
            river_window_v1_propose_dimensions(v->handle, out_w, 30);
            // Pin to absolute bottom of the output
            river_node_v1_set_position(v->node,
                primary->x,
                primary->y + out_h - 30);
            river_node_v1_place_top(v->node);
            river_window_v1_show(v->handle);
        } else {
            // Desktop / app windows get fullscreened
            river_window_v1_fullscreen(v->handle, primary->handle);
            river_node_v1_set_position(v->node, primary->x, primary->y);
            river_window_v1_show(v->handle);
        }
    }
}

void RiverWM::handle_seat(river_seat_v1*) {}
void RiverWM::handle_unavailable() { std::exit(0); }

void RiverWM::run() {
    std::cout << "[Rinux] Active in Monocle Mode..." << std::endl;
    while (wl_display_dispatch(display) != -1) {}
}