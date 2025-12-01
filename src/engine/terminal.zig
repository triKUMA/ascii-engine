const std = @import("std");
const platform = @import("platform.zig");

pub const Terminal = struct {
    width: u16,
    height: u16,

    pub fn init() !Terminal {
        const size = try platform.backend.getTerminalSize();
        return Terminal{
            .width = size.width,
            .height = size.height,
        };
    }

    pub fn refreshSize(self: *Terminal) !bool {
        const size = try platform.backend.getTerminalSize();
        if (self.width != size.width or self.height != size.height) {
            self.width = size.width;
            self.height = size.height;
            return true;
        }

        return false;
    }

    pub fn flush(_: *Terminal, bytes: []const u8) !void {
        try platform.backend.flush(bytes);
    }

    pub fn flushUnicode(_: *Terminal, codepoints: []const u21, allocator: *const std.mem.Allocator) !void {
        try platform.backend.flushUnicode(codepoints, allocator);
    }
};
