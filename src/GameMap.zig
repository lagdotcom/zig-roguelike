const std = @import("std");
const Allocator = std.mem.Allocator;

const Set = @import("ziglangSet").Set;

const t = @import("Tile.zig");
const Terminal = @import("Terminal.zig").Terminal;

const p = @import("procgen.zig");

const common = @import("common.zig");

pub const GameMap = struct {
    pub const Coord = i16;
    pub const Index = usize;

    allocator: Allocator,
    width: usize,
    height: usize,
    tileCount: usize,
    tiles: []t.Tile,
    visible: []bool,
    explored: []bool,
    blocked: Set(Index),

    pub fn init(allocator: Allocator, width: usize, height: usize) !GameMap {
        const tileCount = width * height;

        const map = GameMap{
            .allocator = allocator,
            .width = width,
            .height = height,
            .tileCount = tileCount,
            .tiles = try allocator.alloc(t.Tile, tileCount),
            .visible = try allocator.alloc(bool, tileCount),
            .explored = try allocator.alloc(bool, tileCount),
            .blocked = Set(Index).init(allocator),
        };

        return map;
    }

    pub fn deinit(self: GameMap) void {
        self.allocator.free(self.tiles);
    }

    pub inline fn contains(self: GameMap, x: Coord, y: Coord) bool {
        return x >= 0 and y >= 0 and x < self.width and y < self.height;
    }

    pub inline fn getIndex(self: GameMap, x: Coord, y: Coord) Index {
        return @as(Index, @intCast(y)) * self.width + @as(Index, @intCast(x));
    }

    pub inline fn getPoint(self: GameMap, i: Index) common.Point {
        const x: Coord = @intCast(i % self.width);
        const y: Coord = @intCast(i / self.width);
        return .{ .x = x, .y = y };
    }

    pub fn setTile(self: GameMap, x: Coord, y: Coord, tile: t.Tile) !void {
        if (!self.contains(x, y)) return error.OutOfBounds;
        self.tiles[self.getIndex(x, y)] = tile;
    }

    pub fn getTile(self: GameMap, x: Coord, y: Coord) t.Tile {
        return if (self.contains(x, y)) self.tiles[self.getIndex(x, y)] else t.wall;
    }

    pub fn setBlocked(self: *GameMap, x: Coord, y: Coord) !void {
        _ = try self.blocked.add(self.getIndex(x, y));
    }

    pub fn isBlocked(self: GameMap, x: Coord, y: Coord) bool {
        return self.blocked.contains(self.getIndex(x, y));
    }

    pub fn fill(self: GameMap, tile: t.Tile) !void {
        for (0..self.tileCount) |i| {
            self.tiles[i] = tile;
            self.visible[i] = false;
            self.explored[i] = false;
        }
    }

    pub fn isVisible(self: GameMap, x: Coord, y: Coord) bool {
        return if (self.contains(x, y)) self.visible[self.getIndex(x, y)] else false;
    }

    pub fn setVisible(self: GameMap, x: Coord, y: Coord, visible: bool) void {
        if (self.contains(x, y)) {
            const index = self.getIndex(x, y);
            self.visible[index] = visible;
            if (visible) {
                self.explored[index] = true;
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
        var x: Coord = 0;
        var y: Coord = 0;

        for (0..self.tileCount) |index| {
            const tile = self.tiles[index];
            const visible = self.visible[index];
            const explored = self.explored[index];

            const glyph = if (visible) tile.light else if (explored) tile.dark else t.shroud;

            try term.setChar(x, y, glyph.fg, glyph.bg, glyph.ch);

            x += 1;
            if (x >= self.width) {
                x = 0;
                y += 1;
            }
        }
    }
};
