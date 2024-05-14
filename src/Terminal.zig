const std = @import("std");
const ansi = @import("ansi.zig");

pub fn Terminal(comptime BufferedType: type) type {
    return struct {
        allocator: std.mem.Allocator,
        buffered: BufferedType,
        width: i16,
        height: i16,

        const Self = @This();

        pub fn present(self: *Self) !void {
            try self.buffered.flush();
        }

        pub fn setWindowTitle(self: *Self, title: []const u8) !void {
            const string = try std.fmt.allocPrint(self.allocator, ansi.set_window_title, .{title});
            defer self.allocator.free(string);

            _ = try self.buffered.write(string);
        }

        pub fn setCursorVisible(self: *Self, show: bool) !void {
            _ = try self.buffered.write(if (show) ansi.show_cursor else ansi.hide_cursor);
        }

        pub fn clear(self: *Self) !void {
            try self.at(0, 0);
            _ = try self.buffered.write(ansi.erase_in_display_to_end);
        }

        pub fn at(self: *Self, x: i16, y: i16) !void {
            const string = try std.fmt.allocPrint(self.allocator, ansi.cursor_position, .{ y, x });
            defer self.allocator.free(string);

            _ = try self.buffered.write(string);
        }

        pub fn printAt(self: *Self, x: i16, y: i16, string: []const u8) !void {
            try self.at(x, y);
            _ = try self.buffered.write(string);
        }

        pub fn softReset(self: *Self) !void {
            _ = try self.buffered.write(ansi.soft_reset);
        }
    };
}

pub fn init(
    buffered: anytype,
    width: i16,
    height: i16,
    allocator: std.mem.Allocator,
) Terminal(@TypeOf(buffered)) {
    return .{
        .buffered = buffered,
        .width = width,
        .height = height,
        .allocator = allocator,
    };
}
