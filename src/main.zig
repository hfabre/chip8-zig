const std = @import("std");
const scr = @import("screen.zig");
const rdr = @import("renderer.zig");
const c = @import("cpu.zig");

pub fn main() anyerror!void {
    const scale = 10;
    const fps = 60;
    const fpms = 1000 / fps;

    var previous_time = std.time.milliTimestamp();
    var current_time = previous_time;
    var elapsed_time: i64 = undefined;

    var screen = scr.Screen{};
    const renderer = rdr.Renderer.init("Chip-8", scr.Screen.rows * scale, scr.Screen.cols * scale, true);
    var ram = std.mem.zeroes([4096]u8);
    var cpu = c.Cpu.init(&screen, &ram);
    try cpu.load_game("./roms/ibm_logo.ch8");

    while(!renderer.should_close()) {
        // Draw in first so we see current state before opcode execution
        renderer.draw_debug(cpu.screen.*, scale, cpu);

        current_time = std.time.milliTimestamp();
        elapsed_time = current_time - previous_time;

        if (elapsed_time > fpms) {
            cpu.tick();
        }

        cpu.update_timers();
        cpu.play_sound();
        std.time.sleep(100000000);
    }

    renderer.deinit();
}

