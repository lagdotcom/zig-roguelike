const std = @import("std");
const Random = std.rand;

const entt = @import("entt");
const Entity = entt.Entity;
const Registry = entt.Registry;

const c = @import("components.zig");
const col = @import("colours.zig");
const GameMap = @import("GameMap.zig").GameMap;
const Point = @import("common.zig").Point;
const t = @import("Tile.zig");
const RandomTable = @import("RandomTable.zig").RandomTable;
const spawn = @import("spawn.zig");
const monster = @import("entities/monsters.zig");
const item = @import("entities/items.zig");

pub const RectangularRoom = struct {
    x1: GameMap.Coord,
    y1: GameMap.Coord,
    x2: GameMap.Coord,
    y2: GameMap.Coord,

    pub fn init(x: GameMap.Coord, y: GameMap.Coord, width: GameMap.Coord, height: GameMap.Coord) RectangularRoom {
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
    x: GameMap.Coord,
    y: GameMap.Coord,

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
    max_items_per_room: usize,
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
            try map.set_blocked(centre.x, centre.y);
        } else {
            try tunnel_between(rand, map, rooms.getLast().centre(), new_room.centre());
            try place_entities(reg, rand, new_room, map, max_monsters_per_room, max_items_per_room);
        }

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
        try map.set_tile(x, y, t.floor);

        x += dx;
        y += dy;
    }
}

fn place_entities(
    reg: *Registry,
    rand: Random,
    room: RectangularRoom,
    map: *GameMap,
    maximum_monsters: usize,
    maximum_items: usize,
) !void {
    const number_of_monsters = rand.intRangeAtMost(usize, 0, maximum_monsters);
    var monster_table = RandomTable(spawn.Spawner, i32).init(reg.allocator);
    defer monster_table.deinit();
    try monster_table.add(monster.orc, 4);
    try monster_table.add(monster.troll, 1);

    for (0..number_of_monsters) |_| {
        const x = rand.intRangeAtMost(GameMap.Coord, room.x1 + 1, room.x2 - 1);
        const y = rand.intRangeAtMost(GameMap.Coord, room.y1 + 1, room.y2 - 1);

        if (!map.is_blocked(x, y)) {
            try map.set_blocked(x, y);
            const e = spawn.monster(reg, x, y);
            monster_table.get(rand).init(reg, e);
        }
    }

    const number_of_items = rand.intRangeAtMost(usize, 0, maximum_items);
    var item_table = RandomTable(spawn.Spawner, i32).init(reg.allocator);
    defer item_table.deinit();
    try item_table.add(item.health_potion, 1);
    try item_table.add(item.magic_missile_scroll, 1);
    try item_table.add(item.fireball_scroll, 1);
    try item_table.add(item.confusion_scroll, 1);

    for (0..number_of_items) |_| {
        const x = rand.intRangeAtMost(GameMap.Coord, room.x1 + 1, room.x2 - 1);
        const y = rand.intRangeAtMost(GameMap.Coord, room.y1 + 1, room.y2 - 1);

        if (!map.is_blocked(x, y)) {
            try map.set_blocked(x, y);
            const e = spawn.item(reg, x, y);
            item_table.get(rand).init(reg, e);
        }
    }
}
