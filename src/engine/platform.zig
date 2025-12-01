const std = @import("std");
const backend = switch (@import("builtin").os.tag) {
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

    backend.disableRawMode() catch {};
    backend.exitAltScreen() catch {};

    std.debug.print("Platform revert complete.\n", .{});
}

pub fn getTerminalSize() !backend.TerminalSize {
    return backend.getTerminalSize();
}

pub fn shouldQuit() bool {
    return backend.shouldQuit();
}
