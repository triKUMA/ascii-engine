const platform = @import("platform.zig");

pub const Terminal = struct {
    width: u16,
    height: u16,

    pub fn init() !Terminal {
        const size = try platform.getTerminalSize();
        return Terminal{
            .width = size.width,
            .height = size.height,
        };
    }

    pub fn refreshSize(self: *Terminal) !bool {
        const size = try platform.getTerminalSize();
        if (self.width != size.width or self.height != size.height) {
            self.width = size.width;
            self.height = size.height;
            return true;
        }

        return false;
    }
};
