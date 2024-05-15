const std = @import("std");

const ansi = @import("ansi.zig");
const colours = @import("colours.zig");
const console = @import("console.zig");

pub const Terminal = struct {
    buffer: std.io.BufferedWriter(4096, std.fs.File.Writer),
    file: std.fs.File,
    width: i16,
    height: i16,

    const Self = @This();

    pub fn init(file: std.fs.File, title: []const u8) !Terminal {
        if (!file.supportsAnsiEscapeCodes()) return error.ConsoleDoesNotSupportAnsi;

        const size = console.getSize(file);

        var term = Terminal{
            .file = file,
            .buffer = std.io.bufferedWriter(file.writer()),
            .width = size.width,
            .height = size.height,
        };

        try term.setWindowTitle(title);
        try term.clear();
        try term.at(0, 0);
        try term.setCursorVisible(false);

        return term;
    }

    pub fn deinit(self: *Self) !void {
        try self.present();
        try self.softReset();
        try self.at(0, 0);
        try self.clear();
        try self.present();
    }

    pub fn present(self: *Self) !void {
        try self.buffer.flush();
    }

    pub fn setWindowTitle(self: *Self, title: []const u8) !void {
        try self.buffer.writer().print(ansi.set_window_title, .{title});
    }

    pub fn setCursorVisible(self: *Self, show: bool) !void {
        _ = try self.buffer.write(if (show) ansi.show_cursor else ansi.hide_cursor);
    }

    pub fn clear(self: *Self) !void {
        try self.at(0, 0);
        _ = try self.buffer.write(ansi.erase_in_display_to_end);
    }

    pub fn at(self: *Self, x: i16, y: i16) !void {
        try self.buffer.writer().print(ansi.cursor_position, .{ y + 1, x + 1 });
    }

    pub fn printAt(self: *Self, x: i16, y: i16, comptime format: []const u8, args: anytype) !void {
        try self.at(x, y);
        try self.buffer.writer().print(format, args);
    }

    pub fn softReset(self: *Self) !void {
        _ = try self.buffer.write(ansi.soft_reset);
    }

    pub fn setForegroundColour(self: *Self, rgb: colours.RGB8) !void {
        try self.buffer.writer().print(ansi.sgr_foreground_rgb, .{ rgb.r, rgb.g, rgb.b });
    }

    pub inline fn contains(self: *Self, x: i16, y: i16) bool {
        return x >= 0 and y >= 0 and x < self.width and y < self.height;
    }
};
