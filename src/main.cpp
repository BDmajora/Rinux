#include "../include/RiverWM.hpp"

int main(int argc, char* argv[]) {
    RiverWM wm;
    if (!wm.connect()) return 1;
    wm.run();
    return 0;
}