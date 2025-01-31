const std = @import("std");
const Allocator = std.mem.Allocator;
const Set = @import("ziglangSet").Set;

const col = @import("colours.zig");
const common = @import("common.zig");
const gen = @import("procedural_generation.zig");
const t = @import("Tile.zig");
const Terminal = @import("Terminal.zig").Terminal;

pub const BGOverlay = struct {
    indices: GameMap.IndexSet,
    bg: col.RGB8,
};

pub const GameMap = struct {
    pub const Coord = i16;
    pub const Index = usize;
    pub const IndexSet = Set(Index);

    allocator: Allocator,
    width: usize,
    height: usize,
    tile_count: usize,
    tiles: []t.Tile,
    visible: []bool,
    explored: []bool,
    blocked: IndexSet,

    pub fn init(allocator: Allocator, width: usize, height: usize) !GameMap {
        const tile_count = width * height;

        const map = GameMap{
            .allocator = allocator,
            .width = width,
            .height = height,
            .tile_count = tile_count,
            .tiles = try allocator.alloc(t.Tile, tile_count),
            .visible = try allocator.alloc(bool, tile_count),
            .explored = try allocator.alloc(bool, tile_count),
            .blocked = IndexSet.init(allocator),
        };

        return map;
    }

    pub fn deinit(self: GameMap) void {
        self.allocator.free(self.tiles);
    }

    pub inline fn contains(self: GameMap, x: Coord, y: Coord) bool {
        return x >= 0 and y >= 0 and x < self.width and y < self.height;
    }

    pub inline fn clamp_x(self: GameMap, x: Coord) Coord {
        return @min(self.width - 1, @max(x, 0));
    }

    pub inline fn clamp_y(self: GameMap, y: Coord) Coord {
        return @min(self.height - 1, @max(y, 0));
    }

    pub inline fn get_index(self: GameMap, x: Coord, y: Coord) Index {
        return @as(Index, @intCast(y)) * self.width + @as(Index, @intCast(x));
    }

    pub inline fn get_point(self: GameMap, i: Index) common.Point {
        const x: Coord = @intCast(i % self.width);
        const y: Coord = @intCast(i / self.width);
        return .{ .x = x, .y = y };
    }

    pub fn set_tile(self: GameMap, x: Coord, y: Coord, tile: t.Tile) !void {
        if (!self.contains(x, y)) return error.OutOfBounds;
        self.tiles[self.get_index(x, y)] = tile;
    }

    pub fn get_tile(self: GameMap, x: Coord, y: Coord) t.Tile {
        return if (self.contains(x, y)) self.tiles[self.get_index(x, y)] else t.wall;
    }

    pub fn set_blocked(self: *GameMap, x: Coord, y: Coord) !void {
        _ = try self.blocked.add(self.get_index(x, y));
    }

    pub fn is_blocked(self: GameMap, x: Coord, y: Coord) bool {
        return self.blocked.contains(self.get_index(x, y));
    }

    pub fn fill(self: GameMap, tile: t.Tile) !void {
        for (0..self.tile_count) |i| {
            self.tiles[i] = tile;
            self.visible[i] = false;
            self.explored[i] = false;
        }
    }

    pub fn is_visible(self: GameMap, x: Coord, y: Coord) bool {
        return if (self.contains(x, y)) self.visible[self.get_index(x, y)] else false;
    }

    pub fn set_visible(self: GameMap, x: Coord, y: Coord, visible: bool) void {
        if (self.contains(x, y)) {
            const index = self.get_index(x, y);
            self.visible[index] = visible;
            if (visible) {
                self.explored[index] = true;
            }
        }
    }

    pub fn carve(self: GameMap, room: gen.RectangularRoom) !void {
        var iter = room.inner().iterate();
        while (iter.next()) |point| {
            try self.set_tile(point.x, point.y, t.floor);
        }
    }

    pub fn draw(self: GameMap, term: *Terminal, overlays: []const BGOverlay) !void {
        var x: Coord = 0;
        var y: Coord = 0;

        for (0..self.tile_count) |index| {
            const tile = self.tiles[index];
            const visible = self.visible[index];
            const explored = self.explored[index];

            const glyph = if (visible) tile.light else if (explored) tile.dark else t.shroud;

            var bg = glyph.bg;
            for (overlays) |overlay| {
                if (overlay.indices.contains(index)) {
                    bg = overlay.bg;
                    break;
                }
            }

            try term.set_char(x, y, glyph.fg, bg, glyph.ch);

            x += 1;
            if (x >= self.width) {
                x = 0;
                y += 1;
            }
        }
    }
};
