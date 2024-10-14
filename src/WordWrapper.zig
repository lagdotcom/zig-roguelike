const std = @import("std");

const SpaceFinder = struct {
    dead: bool,
    index: usize,
    source: []const u8,

    pub fn init(source: []const u8, index: usize) SpaceFinder {
        return SpaceFinder{ .dead = false, .source = source, .index = index };
    }

    pub fn next(self: *SpaceFinder) ?usize {
        if (self.dead) return null;

        for (self.index..self.source.len) |i| {
            self.index = i + 1;
            if (std.ascii.isWhitespace(self.source[i])) return i;
        }

        self.dead = true;
        return self.source.len;
    }
};

test "finds spaces" {
    var finder = SpaceFinder.init("hello there I am eight", 0);
    try std.testing.expectEqual(5, finder.next().?);
    try std.testing.expectEqual(11, finder.next().?);
    try std.testing.expectEqual(13, finder.next().?);
    try std.testing.expectEqual(16, finder.next().?);
    try std.testing.expectEqual(22, finder.next().?);
    try std.testing.expectEqual(null, finder.next());
}

pub const WordWrapper = struct {
    index: usize,
    source: []const u8,
    width: usize,

    pub fn init(source: []const u8, width: usize) WordWrapper {
        return WordWrapper{ .index = 0, .source = source, .width = width };
    }

    pub fn next(self: *WordWrapper) ?[]const u8 {
        if (self.index >= self.source.len) return null;

        const start = self.index;
        var finder = SpaceFinder.init(self.source, self.index);
        var found_last_space: ?usize = null;
        while (finder.next()) |i| {
            if (i - start > self.width) {
                if (found_last_space) |last| {
                    self.index = last + 1;
                    return self.source[start..last];
                }
            }

            found_last_space = i;
        }

        self.index = self.source.len;
        return self.source[start..];
    }
};

test "wraps properly" {
    var wrapper = WordWrapper.init("Now is the time for all good men to come to the aid of the party.", 12);
    try std.testing.expectEqualStrings("Now is the", wrapper.next().?);
    try std.testing.expectEqualStrings("time for all", wrapper.next().?);
    try std.testing.expectEqualStrings("good men to", wrapper.next().?);
    try std.testing.expectEqualStrings("come to the", wrapper.next().?);
    try std.testing.expectEqualStrings("aid of the", wrapper.next().?);
    try std.testing.expectEqualStrings("party.", wrapper.next().?);
    try std.testing.expectEqual(null, wrapper.next());
}

test "lets huge words through" {
    var wrapper = WordWrapper.init("I feel discombobulated today!", 6);
    try std.testing.expectEqualStrings("I feel", wrapper.next().?);
    try std.testing.expectEqualStrings("discombobulated", wrapper.next().?);
    try std.testing.expectEqualStrings("today!", wrapper.next().?);
    try std.testing.expectEqual(null, wrapper.next());
}
