const std = @import("std");
const File = std.fs.File;

const colours = @import("colours.zig");
const RGB8 = colours.RGB8;

const ansi = @import("ansi.zig");
const console = @import("console.zig");

pub const Terminal = struct {
    buffer: std.io.BufferedWriter(4096, File.Writer),
    file: File,
    width: i16,
    height: i16,

    const Self = @This();

    pub fn init(file: File, title: []const u8) !Terminal {
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

    pub fn resize(self: *Self, width: i16, height: i16) !void {
        self.width = width;
        self.height = height;
        try self.setBackgroundColour(colours.Black);
        try self.clear();
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

    pub fn setChar(self: *Self, x: i16, y: i16, fg: RGB8, bg: RGB8, ch: u8) !void {
        try self.buffer.writer().print(ansi.cursor_position ++ ansi.sgr_foreground_rgb ++ ansi.sgr_background_rgb ++ "{c}", .{ y + 1, x + 1, fg.r, fg.g, fg.b, bg.r, bg.g, bg.b, ch });
    }

    pub fn softReset(self: *Self) !void {
        _ = try self.buffer.write(ansi.soft_reset);
    }

    pub fn setForegroundColour(self: *Self, rgb: RGB8) !void {
        try self.buffer.writer().print(ansi.sgr_foreground_rgb, .{ rgb.r, rgb.g, rgb.b });
    }

    pub fn setBackgroundColour(self: *Self, rgb: RGB8) !void {
        try self.buffer.writer().print(ansi.sgr_background_rgb, .{ rgb.r, rgb.g, rgb.b });
    }

    pub inline fn contains(self: *Self, x: i16, y: i16) bool {
        return x >= 0 and y >= 0 and x < self.width and y < self.height;
    }
};
