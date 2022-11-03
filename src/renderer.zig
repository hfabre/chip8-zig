const rl = @import("raylib");
const scr = @import("screen.zig");
const cpu = @import("cpu.zig");
const std = @import("std");

const debug_width_offset: u32 = 200;
const debug_height_offset: u32 = 230;

pub const Renderer = struct {
    width: u32,
    height: u32,
    debug: bool,

    pub fn init(title: []const u8, width: u32, height: u32, debug: bool) Renderer {
        var final_width: u32 = width;
        var final_height: u32 = height;

        if (debug) {
            final_width += debug_width_offset;
            final_height += debug_height_offset;
        }

        rl.InitWindow(@intCast(c_int, final_width), @intCast(c_int, final_height), @ptrCast([*c]const u8, title));

        return Renderer {
            .width = final_width,
            .height = final_height,
            .debug = debug
        };
    }

    pub fn deinit(_: Renderer) void {
        rl.CloseWindow();
    }

    pub fn should_close(_: Renderer) bool {
        return rl.WindowShouldClose();
    }

    pub fn draw(self: Renderer, screen: scr.Screen, scale: u32) void {
        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.BLACK);

        self.draw_screen(screen, scale);
    }

    pub fn draw_debug(self: Renderer, screen: scr.Screen, scale: u32, cpu_state: cpu.Cpu) void {
        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.BLACK);

        self.draw_screen(screen, scale);
        self.draw_debug_overlay(cpu_state);
    }

    fn draw_screen(_: Renderer, screen: scr.Screen, scale: u32) void {
        for (screen.pixels) |pixel, i| {
            if (pixel != 0) {
                var x = (i % scr.Screen.cols) * scale;
                var y = (i / scr.Screen.cols) * scale;

                rl.DrawRectangle(@intCast(c_int, x), @intCast(c_int, y), @intCast(c_int, scale), @intCast(c_int, scale), rl.WHITE);
            }
        }
    }

    fn draw_debug_overlay(self: Renderer, cpu_state: cpu.Cpu) void {
        // Vertical sep
        rl.DrawLine(@intCast(c_int, self.debug_width_start()), @intCast(c_int, 0), @intCast(c_int, self.debug_width_start()), @intCast(c_int, self.debug_height_start()), rl.YELLOW);
        // Horizontal sep
        rl.DrawLine(@intCast(c_int, 0), @intCast(c_int, self.debug_height_start()), @intCast(c_int, self.width), @intCast(c_int, self.debug_height_start()), rl.YELLOW);
        // Variable vertical sep
        rl.DrawLine(@intCast(c_int, 210), @intCast(c_int, self.debug_height_start()), @intCast(c_int, 210), @intCast(c_int, self.height), rl.YELLOW);
        // Timer vertical sep
        rl.DrawLine(@intCast(c_int, 320), @intCast(c_int, self.debug_height_start()), @intCast(c_int, 320), @intCast(c_int, self.height), rl.YELLOW);

        self.draw_opcode_debug_overlay(cpu_state, self.debug_width_start(), 0);
        self.draw_var_registers_debug_overlay(cpu_state, 0, self.debug_height_start());
        self.draw_timers_debug_overlay(cpu_state, 210, self.debug_height_start());
    }

    fn draw_fmt_text(_: Renderer, txt: [*c]const u8, x: usize, y: usize, color: rl.Color) void {
        rl.DrawText(txt, @intCast(c_int, x), @intCast(c_int, y), @intCast(c_int, 12), color);
    }

    fn debug_height_start(self: Renderer) u32 {
        return (self.height - debug_height_offset);
    }

    fn debug_width_start(self: Renderer) u32 {
        return (self.width - debug_width_offset);
    }

    fn draw_timers_debug_overlay(self: Renderer, cpu_state: cpu.Cpu, x_offset: u32, y_offset: u32) void {
        var delay_txt = rl.FormatText("Delay timer: %d", @intCast(c_int, cpu_state.delay_timer));
        var sound_txt = rl.FormatText("Sound timer: %d", @intCast(c_int, cpu_state.sound_timer));

        rl.DrawText("Timers", @intCast(c_int, x_offset + 10), @intCast(c_int, y_offset + 10), @intCast(c_int, 20), rl.WHITE);
        self.draw_fmt_text(delay_txt, x_offset + 10, y_offset + 50, rl.WHITE);
        self.draw_fmt_text(sound_txt, x_offset + 10, y_offset + 80, rl.WHITE);
    }

    fn draw_var_registers_debug_overlay(self: Renderer, cpu_state: cpu.Cpu, x_offset: u32, y_offset: u32) void {
        // var i: usize = 0;

        rl.DrawText("Variable registers", @intCast(c_int, x_offset + 10), @intCast(c_int, y_offset + 10), @intCast(c_int, 20), rl.WHITE);

        for (cpu_state.variable_registers) |value, i| {
            var txt = rl.FormatText("V%X: 0x%04X", @intCast(c_int, i), @intCast(c_int, value));

            var x: usize = x_offset + 10;
            var y: usize = y_offset + ((i * 20) + 50);

            if (i > 7) {
                x = x_offset + 100;
                y = y_offset + (((i - 8) * 20) + 50);
            }

            self.draw_fmt_text(txt, x, y, rl.WHITE);
        }
    }

    fn draw_opcode_debug_overlay(self: Renderer, cpu_state: cpu.Cpu, x_offset: u32, y_offset: u32) void {
        rl.DrawText("Opcode", @intCast(c_int, x_offset + 10), @intCast(c_int, y_offset + 10), @intCast(c_int, 20), rl.WHITE);

        var instruction_index: usize = 0;
        while (instruction_index <= 20) {
            if (!(@intCast(usize, cpu_state.current_address) - instruction_index - 10 < cpu.start_address)) {
                var x = x_offset + 10;
                var y = y_offset + ((instruction_index / 2) * 20) + 50;
                var index = @intCast(usize, cpu_state.current_address) + instruction_index - 10;
                var msg = rl.FormatText("0x%04X from 0x%04X", @intCast(c_int, cpu_state.opcode_from_address(@intCast(u16, index))), @intCast(c_int, index));
                var color = switch(instruction_index) {
                    0...9 => rl.RED,
                    11...20 => rl.GREEN,
                    else => rl.WHITE
                };

                self.draw_fmt_text(msg, x, y, color);
            }

            instruction_index += 2;
        }

        var msg = rl.FormatText("Current address: 0x%04X", @intCast(c_int, cpu_state.current_address));
        self.draw_fmt_text(msg, x_offset + 10, y_offset + 280, rl.WHITE);
    }
};
