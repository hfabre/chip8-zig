const std = @import("std");

pub const Screen = struct {
    pub const cols = 32;
    pub const rows = 64;

    pixels: [Screen.cols * Screen.rows]u1 = [_]u1{0} ** (Screen.cols * Screen.rows),

    pub fn toogle_pixel(self: *Screen, og_x: u32, og_y: u32) bool {
        var x = og_x;
        var y = og_y;

        // If a pixel is out of bound, it wraps to the opposite side
        if (x > Screen.cols) {
            x -= Screen.cols;
        } else if (x < 0) {
            x += Screen.cols;
        }

        if (y > Screen.rows) {
            y -= Screen.rows;
        } else if (y < 0) {
            y += Screen.rows;
        }

        const pixel_index = x + (y * Screen.cols);

        // Chip8 games toogle pixels instead of drawing or erasing
        self.pixels[pixel_index] ^= 1;

        // Chip8 games expect the drawing instructions to tell if it has drawn or not
        // We return true if it has drawn, false otherwise
        return self.pixels[pixel_index] == 0;
    }

    pub fn clear(self: *Screen) void {
        self.pixels = std.mem.zeroes([Screen.cols * Screen.rows]u1);
    }
};
