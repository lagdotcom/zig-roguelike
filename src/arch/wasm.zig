const std = @import("std");

const Engine = @import("../Engine.zig").Engine;
const windows = @import("windows.zig");

// WASM Interface
pub const ConsoleSize = struct { width: i16, height: i16 };

extern fn getConsoleInput(handle: i32, buffer: [*]windows.INPUT_RECORD_W, len: usize) u32;
extern fn getConsoleMode(handle: i32) u32;
extern fn getConsoleSize(handle: i32, dimensions: *ConsoleSize) void;
extern fn getRandomBytes(buffer: [*]u8, len: usize) void;
extern fn setConsoleMode(handle: i32, mode: u32) void;
extern fn setEngineAddress(addr: *Engine) void;
extern fn writeToHandle(handle: i32, data: [*]const u8, len: usize) void;

pub const File = struct {
    handle: i32,

    const Self = @This();

    pub fn supportsAnsiEscapeCodes(_: Self) bool {
        return true;
    }

    pub fn writer(f: Self) Writer {
        return Writer{ .context = f };
    }

    fn file_write(f: File, data: []const u8) error{}!usize {
        writeToHandle(f.handle, data.ptr, data.len);
        return data.len;
    }

    pub const Writer = std.io.GenericWriter(File, error{}, file_write);
};

pub fn get_stdin() File {
    return .{ .handle = 0 };
}
pub fn get_stdout() File {
    return .{ .handle = 1 };
}
pub fn get_stderr() File {
    return .{ .handle = 2 };
}

pub fn get_console_size(f: File) ConsoleSize {
    var dimensions = ConsoleSize{ .width = 0, .height = 0 };
    getConsoleSize(f.handle, &dimensions);
    return dimensions;
}

pub fn get_random(buffer: []u8) !void {
    getRandomBytes(buffer.ptr, buffer.len);
}

pub fn set_console_mode(f: File, mode: u32) u32 {
    const oldMode = getConsoleMode(f.handle);
    setConsoleMode(f.handle, mode);

    return oldMode;
}

pub fn get_console_input_records(f: File, buffer: []windows.INPUT_RECORD_W) u32 {
    return getConsoleInput(f.handle, buffer.ptr, buffer.len);
}

pub const run_forever = false;
pub fn ready(engine: *Engine) void {
    setEngineAddress(engine);
}
