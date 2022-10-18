const rl = @import("raylib");
const scr = @import("screen.zig");
const std = @import("std");

pub const Renderer = struct {
    width: u32,
    height: u32,

    pub fn init(title: []const u8, width: u32, height: u32) Renderer {
        rl.InitWindow(@intCast(c_int, width), @intCast(c_int, height), @ptrCast([*c]const u8, title));

        return Renderer {
            .width = width,
            .height = height
        };
    }

    pub fn deinit(_: Renderer) void {
        rl.CloseWindow();
    }

    pub fn should_close(_: Renderer) bool {
        return rl.WindowShouldClose();
    }

    pub fn draw(_: Renderer, screen: scr.Screen, scale: u32) void {
        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);
        var y: usize = 0;

        for (screen.pixels) |pixel, i| {
            if (pixel != 0) {
                // var x = (i % scr.Screen.cols) * scale;
                // var y = (i / scr.Screen.cols) * scale;

                // rl.DrawRectangle(@intCast(c_int, x), @intCast(c_int, y), @intCast(c_int, scale), @intCast(c_int, scale), rl.WHITE);
            }
            y = i;
        }

        std.log.debug("Scale {d}, end screen at {d}", .{scale, y});
        rl.EndDrawing();
    }
};
