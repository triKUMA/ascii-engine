const std = @import("std");
const os = std.os;
const win = std.os.windows;
const AnsiCodes = @import("../ansi.zig").AnsiCodes;

pub const WinError = error{
    GetStdHandleFailed,
    GetConsoleModeFailed,
    SetConsoleModeFailed,
    GetConsoleScreenBufferInfoFailed,
    GetConsoleCPFailed,
};

var out_handle: ?win.HANDLE = null;
var in_handle: ?win.HANDLE = null;
var original_out_mode: u32 = 0;
var original_in_mode: u32 = 0;
var original_out_cp: c_uint = 0;

var should_quit = false;

export fn win_ctrl_handler(_: u32) callconv(.winapi) c_int {
    should_quit = true;
    return 1;
}

pub fn shouldQuit() bool {
    return should_quit;
}

pub fn info() void {
    std.debug.print("Windows backend active\n", .{});
}

fn ensureHandles() !void {
    if (out_handle != null and in_handle != null) return;

    const hOut = try win.GetStdHandle(win.STD_OUTPUT_HANDLE);
    const hIn = try win.GetStdHandle(win.STD_INPUT_HANDLE);

    out_handle = hOut;
    in_handle = hIn;

    return;
}

pub fn enterAltScreen() !void {
    try ensureHandles();

    std.debug.print("Entering alternate screen buffer...\n", .{});

    // Enter alternate screen buffer and clear it, hide cursor
    const seq = AnsiCodes.Screen.enterAlt ++ AnsiCodes.Screen.clear ++ AnsiCodes.Cursor.home ++ AnsiCodes.Cursor.hide;
    try flush(seq);

    return;
}

pub fn exitAltScreen() !void {
    try ensureHandles();

    std.debug.print("Exiting alternate screen buffer...\n", .{});

    // Restore cursor and leave alternate buffer
    const seq = AnsiCodes.Cursor.show ++ AnsiCodes.Text.Style.reset ++ AnsiCodes.Screen.exitAlt;
    try flush(seq);

    return;
}

pub fn enableRawMode() !void {
    try ensureHandles();

    std.debug.print("Enabling raw mode...\n", .{});

    // Enable VT processing on output so ANSI escape sequences work
    var out_mode: u32 = 0;
    if (win.kernel32.GetConsoleMode(out_handle.?, &out_mode) == 0) {
        return WinError.GetConsoleModeFailed;
    }
    original_out_mode = out_mode;

    const ENABLE_VIRTUAL_TERMINAL_PROCESSING: u32 = 0x0004;
    const new_out_mode = out_mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING;
    if (win.kernel32.SetConsoleMode(out_handle.?, new_out_mode) == 0) {
        return WinError.SetConsoleModeFailed;
    }

    // Input mode: disable line input and echo so we get a more raw-like stream.
    var in_mode: u32 = 0;
    if (win.kernel32.GetConsoleMode(in_handle.?, &in_mode) == 0) {
        // try to restore output mode back before failing
        _ = win.kernel32.SetConsoleMode(out_handle.?, original_out_mode);
        return WinError.GetConsoleModeFailed;
    }
    original_in_mode = in_mode;

    const ENABLE_ECHO_INPUT: u32 = 0x0004;
    const ENABLE_LINE_INPUT: u32 = 0x0002;
    const ENABLE_WINDOW_INPUT: u32 = 0x0008;
    const ENABLE_PROCESSED_INPUT: u32 = 0x0001;

    // Turn off echo & line input (so input is not buffered by the console)
    var new_in_mode = in_mode & ~(ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT);
    // Keep processed input so Ctrl+C still generates a console control event
    new_in_mode |= ENABLE_WINDOW_INPUT | ENABLE_PROCESSED_INPUT;

    // Best-effort: if SetConsoleMode fails, restore out mode and report error
    if (win.kernel32.SetConsoleMode(in_handle.?, new_in_mode) == 0) {
        _ = win.kernel32.SetConsoleMode(out_handle.?, original_out_mode);
        return WinError.SetConsoleModeFailed;
    }

    original_out_cp = win.kernel32.GetConsoleOutputCP();
    if (win.kernel32.SetConsoleOutputCP(65001) == 0) {
        // try to restore original modes before failing
        _ = win.kernel32.SetConsoleMode(out_handle.?, original_out_mode);
        _ = win.kernel32.SetConsoleMode(in_handle.?, original_in_mode);
        return WinError.GetConsoleCPFailed;
    }

    // Install control handler so we can intercept Ctrl+C (graceful handling)
    // best-effort: ignore failure
    _ = win.kernel32.SetConsoleCtrlHandler(win_ctrl_handler, 1);

    return;
}

pub fn disableRawMode() !void {
    try ensureHandles();

    std.debug.print("Disabling raw mode...\n", .{});

    _ = win.kernel32.SetConsoleOutputCP(original_out_cp);

    if (out_handle) |h| {
        // restore original output mode
        _ = win.kernel32.SetConsoleMode(h, original_out_mode);
    }
    if (in_handle) |h| {
        _ = win.kernel32.SetConsoleMode(h, original_in_mode);
    }

    // remove ctrl handler
    _ = win.kernel32.SetConsoleCtrlHandler(win_ctrl_handler, 0);
    return;
}

pub const TerminalSize = struct {
    width: u16,
    height: u16,
};

pub fn getTerminalSize() !TerminalSize {
    try ensureHandles();

    // return .{ .width = 4, .height = 4 };

    var screen_buffer_info: win.CONSOLE_SCREEN_BUFFER_INFO = undefined;
    if (win.kernel32.GetConsoleScreenBufferInfo(out_handle.?, &screen_buffer_info) == 0) {
        return WinError.GetConsoleScreenBufferInfoFailed;
    }

    // srWindow gives the visible window rectangle; compute width/height
    const left = screen_buffer_info.srWindow.Left;
    const right = screen_buffer_info.srWindow.Right;
    const top = screen_buffer_info.srWindow.Top;
    const bottom = screen_buffer_info.srWindow.Bottom;

    const w: u16 = @intCast(right - left + 1);
    const h: u16 = @intCast(bottom - top + 1);

    return .{ .width = if (w == 0) 80 else w, .height = if (h == 0) 30 else h };
}

pub fn flush(buffer: []const u8) !void {
    try ensureHandles();

    var out = std.fs.File.stdout().writer(&.{});
    try out.interface.writeAll(buffer);
    try out.interface.flush();
}

pub fn flushUnicode(codepoint_buffer: []const u21, allocator: *const std.mem.Allocator) !void {
    try ensureHandles();

    var byte_buffer = try allocator.alloc(u8, codepoint_buffer.len * 4);
    defer allocator.free(byte_buffer);

    var byte_buffer_size: usize = 0;
    for (codepoint_buffer) |cp| {
        const slice = byte_buffer[byte_buffer_size .. byte_buffer_size + 4];
        byte_buffer_size += try std.unicode.utf8Encode(cp, slice);
    }

    try flush(byte_buffer[0..byte_buffer_size]);
}
