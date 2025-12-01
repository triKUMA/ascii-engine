const std = @import("std");

pub fn info() void {
    std.debug.print("Unix backend active\n", .{});
}
