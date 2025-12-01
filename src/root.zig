const std = @import("std");
const platform = @import("engine/platform.zig");
const Terminal = @import("engine/terminal.zig").Terminal;
const AnsiCodes = @import("engine/ansi.zig").AnsiCodes;

pub fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    try platform.setup();
    defer platform.revert();

    var terminal = try Terminal.init();

    var frame_count: u64 = 0;
    var timer = try std.time.Timer.start();
    var elapsed: u64 = 1 * std.time.ns_per_hour; // will trigger first frame immediately

    const fps = 5.0;

    while (!platform.backend.shouldQuit()) {
        if (try terminal.refreshSize()) {
            std.debug.print("Terminal resized to {d}x{d}\n", .{ terminal.width, terminal.height });

            try terminal.out.writeAll(AnsiCodes.Screen.clear);
        }

        elapsed += timer.lap();
        if (elapsed >= std.math.floor((1.0 / fps) * std.time.ns_per_s)) {
            try renderFrame(&terminal, &allocator, frame_count);
            elapsed = 0;
            frame_count += 1;
        }
    }
}

fn renderFrame(terminal: *Terminal, allocator: *const std.mem.Allocator, frame_count: u64) !void {
    const chars = [_]u21{ ' ', '░', '▒', '▓' };

    const ansi_frame_header = AnsiCodes.Cursor.home;

    const frame_buffer = try allocator.alloc(u21, ansi_frame_header.len + (terminal.height * (terminal.width + 1)));
    defer allocator.free(frame_buffer);

    for (ansi_frame_header, 0..) |b, i| {
        frame_buffer[i] = b;
    }

    var y: usize = 0;
    while (y < terminal.height) : (y += 1) {
        const row_offset = ansi_frame_header.len + y * (terminal.width + 1);
        var x: usize = 0;
        while (x < terminal.width) : (x += 1) {
            const char = chars[(x + y + frame_count) % chars.len];
            const idx = row_offset + x;
            frame_buffer[idx] = char;
        }

        frame_buffer[row_offset + x] = '\n';
    }

    try terminal.flushUnicode(frame_buffer[0..], allocator);
}
