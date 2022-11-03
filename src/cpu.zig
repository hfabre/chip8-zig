const std = @import("std");
const scr = @import("screen.zig");

// Describe the font (those are the sprite used for hexadecimals number from 0 o F)
const font = [_]u8 {
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80  // F
};

pub const start_address: u16 = 0x200;

pub const Cpu = struct {
    ram: *[4096]u8,
    paused: bool = false,
    stack: std.atomic.Stack(u16) = std.atomic.Stack(u16).init(),
    screen: *scr.Screen,

    // Timers are decremented 60 times per second until we reach 0
    delay_timer: u8 = 60,
    sound_timer: u8 = 60,

    // Variable registers named from V0 to VF, note that VF is often used
    // as a flag register and games use it as a bool.
    variable_registers: [16]u8 = [_]u8{0} ** (16),

    // Register used to store one address often called I
    address_register: u16 = 0,

    // Program counter, it's updated to keep track which instruction we are executing
    // Historically, the interpreter itself was stored in memory between 0x000 and 0x1FFF.
    // Since we don't do it, we start at 0x200
    current_address: u16 = 0x200,

    pub fn init(screen: *scr.Screen, zeroed_ram: *[4096]u8) Cpu {

        // Store font sprites in memory, we can do it anywhere inside the interpreter zone (0x000 and 0x1FFF)
        for (font) |sprite_part, i| {
            zeroed_ram[i] = sprite_part;
        }

        return Cpu {
            .ram = zeroed_ram,
            .screen = screen
        };
    }

    pub fn load_game(self: Cpu, path: []const u8) !void {
        var file = try std.fs.cwd().openFile(path, .{});
        _ = try file.readAll(self.ram[start_address..]);
    }

    pub fn opcode_from_address(self: Cpu, address: u16) u16 {
        const b1 = self.ram[address];
        const b2 = self.ram[address + 1];

        // An opcode takes two slots in memory (u8) so it's a u16.
        // But we can't simply combine the two bytes into one
        // so we right pad our first byte with some 0 (<< 8) to make it
        // two bytes long, then we add the second byte (|)
        return (@as(u16, b1) << 8 | b2);
    }

    pub fn tick(self: *Cpu) void {
        if (!self.paused) {
            var opcode = self.opcode_from_address(self.current_address);
            std.log.debug("Executing opcode 0x{X:0>4} at 0x{X:0>4}", .{opcode, self.current_address});

            // Opcode are two bytes long so we jump directly to the next opcode
            self.current_address += 2;

            self.execute(opcode);
        }
    }

    pub fn play_sound(_: Cpu) void {
        // Not implemented
    }

    pub fn update_timers(self: *Cpu) void {
        if (!self.paused) {
            if (self.delay_timer > 0) {
                self.delay_timer -= 1;
            }

            if (self.sound_timer > 0) {
                self.sound_timer -= 1;
            }
        }
    }

    fn draw(self: *Cpu, opcode: u16, x: u8, y: u8) void {
        var width: u8 = 8;
        var height = (opcode & 0xF);
        var row: u8 = 0;

        self.variable_registers[0xF] = 0;
        while (row < height) : (row += 1) {
            var col: u8 = 0;
            var sprite = self.ram[self.address_register + row];

            while (col < width) : (col += 1) {
                if ((sprite & 0x80) > 0) {

                    if (self.screen.toogle_pixel(self.variable_registers[x] + col, self.variable_registers[y] + row)) {
                        self.variable_registers[0xF] = 1;
                    }
                }
                sprite <<= 1;
            }
        }
    }

    pub fn execute(self: *Cpu, opcode: u16) void {

        // We want to get two 4 bites values
        // X is the lower 4 bits of the high byte
        var x = @intCast(u8, (opcode & 0x0F00) >> 8);

        // Y is the upper 4 bits of the low byte
        var y = @intCast(u8, (opcode & 0x00F0) >> 4);

        switch (opcode) {
            0x00E0 => self.screen.clear(),
            0x00EE => { std.log.debug("Unhandled opcode 0x{X:0>4}", .{opcode}); },
            0x1000...0x1FFF => self.current_address = (opcode & 0x0FFF),
            0x2000...0x2FFF => { std.log.debug("Unhandled opcode 0x{X:0>4}", .{opcode}); },
            0x3000...0x3FFF => { std.log.debug("Unhandled opcode 0x{X:0>4}", .{opcode}); },
            0x4000...0x4FFF => { std.log.debug("Unhandled opcode 0x{X:0>4}", .{opcode}); },
            0x5000...0x5FFF => { std.log.debug("Unhandled opcode 0x{X:0>4}", .{opcode}); },
            0x6000...0x6FFF => self.variable_registers[x] = @intCast(u8, opcode & 0x00FF),
            0x7000...0x7FFF => self.variable_registers[x] += @intCast(u8, opcode & 0x00FF),
            0x8000...0x8FFF => { std.log.debug("Unhandled opcode 0x{X:0>4}", .{opcode}); },
            0x9000...0x9FFF => { std.log.debug("Unhandled opcode 0x{X:0>4}", .{opcode}); },
            0xA000...0xAFFF => self.address_register = (opcode & 0x0FFF),
            0xB000...0xBFFF => { std.log.debug("Unhandled opcode 0x{X:0>4}", .{opcode}); },
            0xC000...0xCFFF => { std.log.debug("Unhandled opcode 0x{X:0>4}", .{opcode}); },
            0xD000...0xDFFF => self.draw(opcode, x, y),
            0xE000...0xEFFF => { std.log.debug("Unhandled opcode 0x{X:0>4}", .{opcode}); },
            0xF000...0xFFFF => { std.log.debug("Unhandled opcode 0x{X:0>4}", .{opcode}); },
            else => {
                std.log.debug("Unknown opcode 0x{X:0>4}", .{opcode});
            }
        }
    }
};
