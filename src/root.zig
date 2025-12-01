const std = @import("std");
const platform = @import("engine/platform.zig");
const Terminal = @import("engine/terminal.zig").Terminal;

pub fn run() !void {
    try platform.setup();
    defer platform.revert();

    var terminal = try Terminal.init();

    while (!platform.shouldQuit()) {
        if (try terminal.refreshSize()) {
            std.debug.print("Terminal resized to {d}x{d}\n", .{ terminal.width, terminal.height });
        }
    }
}
