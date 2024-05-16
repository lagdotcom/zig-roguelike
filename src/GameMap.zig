const std = @import("std");
const Allocator = std.mem.Allocator;

const t = @import("Tile.zig");
const Terminal = @import("Terminal.zig").Terminal;

const p = @import("procgen.zig");

pub const GameMap = struct {
    allocator: Allocator,
    width: usize,
    height: usize,
    tiles: []t.Tile,

    pub fn init(allocator: Allocator, width: usize, height: usize) !GameMap {
        const map = GameMap{
            .allocator = allocator,
            .width = width,
            .height = height,
            .tiles = try allocator.alloc(t.Tile, width * height),
        };

        return map;
    }

    pub fn deinit(self: GameMap) void {
        self.allocator.free(self.tiles);
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
        return if (self.contains(x, y)) self.tiles[self.getIndex(x, y)] else t.wall;
    }

    pub fn fill(self: GameMap, tile: t.Tile) !void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                try self.setTile(@intCast(x), @intCast(y), tile);
            }
        }
    }

    pub fn carve(self: GameMap, room: p.RectangularRoom) !void {
        var iter = room.inner().iterate();
        while (iter.next()) |point| {
            try self.setTile(point.x, point.y, t.floor);
        }
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
