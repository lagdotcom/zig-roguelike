const std = @import("std");
const Random = std.rand;

const Point = @import("common.zig").Point;
const GameMap = @import("GameMap.zig").GameMap;
const t = @import("Tile.zig");

const entt = @import("entt");
const Registry = entt.Registry;

const c = @import("components.zig");

pub const RectangularRoom = struct {
    x1: i16,
    y1: i16,
    x2: i16,
    y2: i16,

    pub fn init(x: i16, y: i16, width: i16, height: i16) RectangularRoom {
        return RectangularRoom{
            .x1 = x,
            .y1 = y,
            .x2 = x + width,
            .y2 = y + height,
        };
    }

    pub fn centre(self: RectangularRoom) Point {
        return Point{
            .x = @divTrunc(self.x1 + self.x2, 2),
            .y = @divTrunc(self.y1 + self.y2, 2),
        };
    }

    pub fn inner(self: RectangularRoom) RectangularRoom {
        return RectangularRoom{
            .x1 = self.x1 + 1,
            .y1 = self.y1 + 1,
            .x2 = self.x2 - 1,
            .y2 = self.y2 - 1,
        };
    }

    pub fn iterate(self: RectangularRoom) RectangularRoomIterator {
        return RectangularRoomIterator.init(self);
    }

    pub fn intersects(self: RectangularRoom, other: RectangularRoom) bool {
        return (self.x1 <= other.x2 and self.x2 >= other.x1 and self.y1 <= other.y2 and self.y2 >= other.y1);
    }
};

pub const RectangularRoomIterator = struct {
    room: RectangularRoom,
    x: i16,
    y: i16,

    pub fn init(room: RectangularRoom) RectangularRoomIterator {
        return RectangularRoomIterator{ .room = room, .x = room.x1, .y = room.y1 };
    }

    pub fn next(self: *RectangularRoomIterator) ?Point {
        if (self.y <= self.room.y2) {
            const point = Point{ .x = self.x, .y = self.y };

            self.x += 1;
            if (self.x > self.room.x2) {
                self.x = self.room.x1;
                self.y += 1;
            }

            return point;
        }

        return null;
    }
};

pub fn generate_dungeon(
    reg: *Registry,
    rand: Random,
    map: *GameMap,
    room_max_size: usize,
    room_min_size: usize,
    max_rooms: usize,
    max_monsters_per_room: usize,
    player_pos: *Point,
) !void {
    var rooms = try std.ArrayList(RectangularRoom).initCapacity(map.allocator, max_rooms);
    defer rooms.deinit();

    try map.fill(t.wall);
    room_loop: for (0..max_rooms) |_| {
        const room_width = rand.intRangeAtMost(usize, room_min_size, room_max_size);
        const room_height = rand.intRangeAtMost(usize, room_min_size, room_max_size);

        const x = rand.intRangeAtMost(usize, 0, map.width - room_width - 1);
        const y = rand.intRangeAtMost(usize, 0, map.height - room_height - 1);

        const new_room = RectangularRoom.init(
            @intCast(x),
            @intCast(y),
            @intCast(room_width),
            @intCast(room_height),
        );

        for (rooms.items) |other|
            if (new_room.intersects(other))
                continue :room_loop;

        try map.carve(new_room);

        if (rooms.items.len == 0) {
            const centre = new_room.centre();
            player_pos.x = centre.x;
            player_pos.y = centre.y;
        } else {
            try tunnel_between(rand, map, rooms.getLast().centre(), new_room.centre());
        }

        try place_entities(reg, rand, new_room, map, max_monsters_per_room);
        try rooms.append(new_room);
    }
}

fn tunnel_between(rand: Random, map: *GameMap, start: Point, end: Point) !void {
    const corner = if (rand.boolean()) Point{ .x = end.x, .y = start.y } else Point{ .x = start.x, .y = end.y };

    try carve_straight_line(map, start, corner);
    try carve_straight_line(map, corner, end);
}

fn carve_straight_line(map: *GameMap, start: Point, end: Point) !void {
    var x = start.x;
    var y = start.y;
    const dx = std.math.sign(end.x - start.x);
    const dy = std.math.sign(end.y - start.y);

    while (x != end.x or y != end.y) {
        try map.setTile(x, y, t.floor);

        x += dx;
        y += dy;
    }
}

fn place_entities(reg: *Registry, rand: Random, room: RectangularRoom, map: *GameMap, maximum_monsters: usize) !void {
    const number_of_monsters = rand.intRangeAtMost(usize, 0, maximum_monsters);

    for (0..number_of_monsters) |_| {
        const x = rand.intRangeAtMost(i16, room.x1 + 1, room.x2 - 1);
        const y = rand.intRangeAtMost(i16, room.y1 + 1, room.y2 - 1);

        if (!map.isBlocked(x, y)) {
            try map.setBlocked(x, y);
            const monster = reg.create();
            reg.add(monster, c.Position{ .x = x, .y = y });
            reg.add(monster, c.BlocksMovement{});
            reg.add(monster, c.IsEnemy{});

            if (rand.float(f32) < 0.8) {
                reg.add(monster, c.Glyph{
                    .ch = 'o',
                    .colour = .{ .r = 63, .g = 127, .b = 63 },
                    .order = c.RenderOrder.Actor,
                });
                reg.add(monster, c.Named{ .name = "Orc" });
                reg.add(monster, c.Fighter{ .hp = 10, .max_hp = 10, .defense = 0, .power = 3 });
                reg.add(monster, c.BaseAI{});
            } else {
                reg.add(monster, c.Glyph{
                    .ch = 'T',
                    .colour = .{ .r = 0, .g = 127, .b = 0 },
                    .order = c.RenderOrder.Actor,
                });
                reg.add(monster, c.Named{ .name = "Troll" });
                reg.add(monster, c.Fighter{ .hp = 16, .max_hp = 16, .defense = 1, .power = 4 });
                reg.add(monster, c.BaseAI{});
            }
        }
    }
}
