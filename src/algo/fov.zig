const std = @import("std");

const GameMap = @import("../GameMap.zig").GameMap;
const Point = @import("../common.zig").Point;
const line = @import("line.zig");

pub const SIGHT_DISTANCE = 10;

var current_map: GameMap = undefined;
fn visit(p: Point) bool {
    current_map.setVisible(p.x, p.y, true);
    return current_map.getTile(p.x, p.y).transparent;
}

pub fn compute(map: GameMap, centre: Point) void {
    for (0..map.tileCount) |i| {
        map.visible[i] = false;
    }

    current_map = map;
    const min_x = centre.x - SIGHT_DISTANCE;
    const max_x = centre.x + SIGHT_DISTANCE;
    const min_y = centre.y - SIGHT_DISTANCE;
    const max_y = centre.y + SIGHT_DISTANCE;

    var x = min_x;
    while (x <= max_x) : (x += 1) {
        var y = min_y;
        while (y <= max_y) : (y += 1) {
            line.trace(centre, .{ .x = x, .y = y }, visit);
        }
    }
}
