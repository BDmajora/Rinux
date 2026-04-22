#ifndef RIVER_WM_HPP
#define RIVER_WM_HPP

#include <wayland-client.h>
extern "C" {
#include "river-window-management-v1-client-protocol.h"
}
#include <vector>
#include <string>
#include <iostream>

struct View {
    river_window_v1* handle  = nullptr;
    river_node_v1*   node    = nullptr;
    std::string      app_id;
    std::string      title;
    // Actual dimensions reported by the compositor via the dimensions event.
    // 0 means not yet received.
    int32_t width  = 0;
    int32_t height = 0;
};

struct OutputInfo {
    river_output_v1* handle = nullptr;
    int32_t x      = 0;
    int32_t y      = 0;
    int32_t width  = 0;
    int32_t height = 0;
};

class RiverWM {
public:
    RiverWM();
    ~RiverWM();

    bool connect();
    void run();

    void handle_global(wl_registry* registry, uint32_t name,
                       const char* interface, uint32_t version);

    void handle_window(river_window_v1* window);
    void handle_manage_start();
    void handle_render_start();
    void handle_output(river_output_v1* output);
    void handle_seat(river_seat_v1* seat);
    void handle_unavailable();
    void set_resolution(int w, int h);
    void layout();

private:
    wl_display*              display  = nullptr;
    wl_registry*             registry = nullptr;
    river_window_manager_v1* river_wm = nullptr;

    int screen_width  = 1280;
    int screen_height = 800;

    std::vector<View*>       views;
    std::vector<OutputInfo*> output_infos;
};

#endif