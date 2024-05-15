const std = @import("std");
const Allocator = std.mem.Allocator;

const t = @import("Tile.zig");
const Terminal = @import("Terminal.zig").Terminal;

pub const GameMap = struct {
    allocator: Allocator,
    width: usize,
    height: usize,
    tiles: []t.Tile,

    pub fn init(allocator: Allocator, comptime width: usize, comptime height: usize) !GameMap {
        const map = GameMap{
            .allocator = allocator,
            .width = width,
            .height = height,
            .tiles = try allocator.alloc(t.Tile, width * height),
        };

        for (0..height) |y| {
            for (0..width) |x| {
                try map.setTile(@intCast(x), @intCast(y), t.floor);
            }
        }

        if (width >= 33 and height >= 22) for (30..33) |y| {
            try map.setTile(@intCast(y), 22, t.wall);
        };

        return map;
    }

    pub inline fn contains(self: GameMap, x: i16, y: i16) bool {
        return x >= 0 and y >= 0 and x < self.width and y < self.height;
    }

    pub inline fn getIndex(self: GameMap, x: i16, y: i16) usize {
        return @as(usize, @intCast(y)) * self.width + @as(usize, @intCast(x));
    }

    pub fn setTile(self: GameMap, x: i16, y: i16, tile: t.Tile) !void {
        if (!self.contains(x, y)) return error.OutOfBounds;
        self.tiles[self.getIndex(x, y)] = tile;
    }

    pub fn getTile(self: GameMap, x: i16, y: i16) t.Tile {
        return if (self.contains(x, y)) self.tiles[self.getIndex(x, y)] else t.floor;
    }

    pub fn deinit(self: GameMap) void {
        self.allocator.free(self.tiles);
    }

    pub fn draw(self: GameMap, term: *Terminal) !void {
        const max_x = @min(self.width, @as(usize, @intCast(term.width)));
        const max_y = @min(self.height, @as(usize, @intCast(term.height)));

        for (0..max_y) |y| {
            for (0..max_x) |x| {
                const tile = self.getTile(@intCast(x), @intCast(y));
                try term.setChar(
                    @intCast(x),
                    @intCast(y),
                    tile.dark.fg,
                    tile.dark.bg,
                    tile.dark.ch,
                );
            }
        }
    }
};
