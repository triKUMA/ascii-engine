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

    // try renderFrame(&terminal, &allocator);

    // std.Thread.sleep(5 * std.time.ns_per_s);

    var frame_count: usize = 0;
    while (!platform.backend.shouldQuit()) : (frame_count += 1) {
        if (try terminal.refreshSize()) {
            std.debug.print("Terminal resized to {d}x{d}\n", .{ terminal.width, terminal.height });
        }

        try renderFrame(&terminal, &allocator, frame_count);
        std.Thread.sleep(1 * std.time.ns_per_s); // ~60 FPS

        try terminal.flush(&[0]u8{});
    }
}

fn renderFrame(terminal: *Terminal, allocator: *const std.mem.Allocator, frame_count: usize) !void {
    const chars = [_]u21{ ' ', '░', '▒', '▓' };

    const ansi_frame_header = AnsiCodes.Screen.clear ++ AnsiCodes.Cursor.home ++ AnsiCodes.Cursor.hide;

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
            const char = chars[(x + y + frame_count) % 4];
            const idx = row_offset + x;
            frame_buffer[idx] = char;
        }

        frame_buffer[row_offset + x] = '\n';
    }

    try terminal.flushUnicode(frame_buffer[0..], allocator);
    try terminal.flush(AnsiCodes.Cursor.hide);
}
