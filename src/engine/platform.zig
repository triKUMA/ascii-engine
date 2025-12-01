const std = @import("std");
pub const backend = switch (@import("builtin").os.tag) {
    .windows => @import("backends/windows.zig"),
    .linux, .macos => @import("backends/unix.zig"),
    else => @panic("unsupported platform"),
};

pub fn setup() !void {
    std.debug.print("Setting up platform...\n", .{});

    try backend.enterAltScreen();
    try backend.enableRawMode();

    backend.info();

    std.debug.print("Platform setup complete.\n", .{});
}

pub fn revert() void {
    std.debug.print("Reverting platform setup...\n", .{});

    backend.restoreOriginalState() catch {};

    std.debug.print("Platform revert complete.\n", .{});
}
