const std = @import("std");
const ascii_engine = @import("ascii_engine");

pub fn main() !void {
    try ascii_engine.run();
}
