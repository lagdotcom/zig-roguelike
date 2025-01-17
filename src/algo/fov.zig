const std = @import("std");

const GameMap = @import("../GameMap.zig").GameMap;
const Point = @import("../common.zig").Point;
const line = @import("line.zig");

pub const sight_distance = 10;

var current_map: GameMap = undefined;
fn visit(p: Point) bool {
    current_map.set_visible(p.x, p.y, true);
    return current_map.get_tile(p.x, p.y).transparent;
}

pub fn compute(map: GameMap, centre: Point) void {
    for (0..map.tile_count) |i| {
        map.visible[i] = false;
    }

    current_map = map;
    const min_x = centre.x - sight_distance;
    const max_x = centre.x + sight_distance;
    const min_y = centre.y - sight_distance;
    const max_y = centre.y + sight_distance;

    var x = min_x;
    while (x <= max_x) : (x += 1) {
        var y = min_y;
        while (y <= max_y) : (y += 1) {
            line.trace(centre, .{ .x = x, .y = y }, visit);
        }
    }
}
