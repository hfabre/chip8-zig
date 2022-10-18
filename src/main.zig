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
    var stop: u32 = 0;

    var screen = scr.Screen{};
    const renderer = rdr.Renderer.init("Chip-8", scr.Screen.rows * scale, scr.Screen.cols * scale);
    var cpu = c.Cpu.init(&screen);
    try cpu.load_game("./roms/ibm_logo.ch8");

    // _ = screen.toogle_pixel(0, 0);
    // _ = screen.toogle_pixel(10, 10);

    std.log.debug("Screen: {*}, Ram: {any}", .{&cpu.screen.pixels, cpu.ram});
    while(!renderer.should_close()) {
        if (stop == 2) {
            std.os.exit(1);
        }
        current_time = std.time.milliTimestamp();
        elapsed_time = current_time - previous_time;

        if (elapsed_time > fpms) {
            cpu.tick();
        }

        cpu.update_timers();
        cpu.play_sound();

        std.log.debug("MAIN BEFORE RENDERING: Memory at 0x{X} 0x{X:0>2}, at 0x{X} 0x{X:0>2}, at 0x{X} 0x{X:0>2}, at 0x{X} 0x{X:0>2}", .{cpu.current_address, cpu.ram[cpu.current_address], cpu.current_address+1, cpu.ram[cpu.current_address+1], cpu.current_address+2, cpu.ram[cpu.current_address+2], cpu.current_address+3, cpu.ram[cpu.current_address+3]});
        renderer.draw(cpu.screen.*, scale);
        std.log.debug("MAIN AFTER RENDREGIN: Memory at 0x{X} 0x{X:0>2}, at 0x{X} 0x{X:0>2}, at 0x{X} 0x{X:0>2}, at 0x{X} 0x{X:0>2}", .{cpu.current_address, cpu.ram[cpu.current_address], cpu.current_address+1, cpu.ram[cpu.current_address+1], cpu.current_address+2, cpu.ram[cpu.current_address+2], cpu.current_address+3, cpu.ram[cpu.current_address+3]});
        stop += 1;
    }
}

