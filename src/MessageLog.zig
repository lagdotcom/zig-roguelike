const std = @import("std");

const co = @import("colours.zig");
const RGB8 = co.RGB8;
const Terminal = @import("Terminal.zig").Terminal;
const WordWrapper = @import("WordWrapper.zig").WordWrapper;

const Message = struct {
    plain_text: []const u8,
    fg: RGB8,
    count: usize,
};

pub const MessageLog = struct {
    messages: std.ArrayList(Message),

    pub fn init(allocator: std.mem.Allocator) !MessageLog {
        return MessageLog{ .messages = std.ArrayList(Message).init(allocator) };
    }

    pub fn deinit(self: *MessageLog) void {
        self.messages.deinit();
    }

    pub fn add(self: *MessageLog, text: []const u8, fg: RGB8, stack: bool) !void {
        if (stack) {
            if (self.messages.getLastOrNull()) |top| {
                if (std.mem.eql(u8, text, top.plain_text)) {
                    self.messages.replaceRangeAssumeCapacity(self.messages.items.len - 1, 1, &.{Message{ .plain_text = text, .fg = fg, .count = top.count + 1 }});
                    return;
                }
            }
        }

        try self.messages.append(Message{ .plain_text = text, .fg = fg, .count = 1 });
    }

    pub fn render(self: *MessageLog, terminal: *Terminal, x: i16, y: i16, width: usize, height: usize) !void {
        const allocator = self.messages.allocator;
        var y_offset: i16 = @intCast(height);

        try terminal.setBackgroundColour(co.Black);
        try terminal.drawRect(x, y, width, height, ' ');

        var iter = std.mem.reverseIterator(self.messages.items);
        while (iter.next()) |message| {
            try terminal.setForegroundColour(message.fg);

            const text = if (message.count > 1) try std.fmt.allocPrint(allocator, "{s} (x{d})", .{ message.plain_text, message.count }) else message.plain_text;

            var lines = std.ArrayList([]const u8).init(allocator);
            defer lines.deinit();

            var wrapper = WordWrapper.init(text, width);
            while (wrapper.next()) |line| try lines.append(line);

            var reverser = std.mem.reverseIterator(lines.items);
            while (reverser.next()) |line| {
                try terminal.printAt(@intCast(x), @intCast(y + y_offset - 1), "{s}", .{line});

                y_offset -= 1;
                if (y_offset == 0) return;
            }
        }
    }
};
