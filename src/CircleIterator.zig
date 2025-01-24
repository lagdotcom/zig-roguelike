const GameMap = @import("GameMap.zig").GameMap;
const Point = @import("common.zig").Point;
const geo = @import("algo/geometry.zig");

pub const CircleIterator = struct {
    map: GameMap,
    cx: GameMap.Coord,
    cy: GameMap.Coord,
    radius: i16,
    x_min: GameMap.Coord,
    x_max: GameMap.Coord,
    y_min: GameMap.Coord,
    y_max: GameMap.Coord,
    x: GameMap.Coord,
    y: GameMap.Coord,

    pub fn init(map: GameMap, cx: GameMap.Coord, cy: GameMap.Coord, radius: i16) CircleIterator {
        const x_min = map.clamp_x(cx - radius);
        const x_max = map.clamp_x(cx + radius);
        const y_min = map.clamp_y(cy - radius);
        const y_max = map.clamp_y(cy + radius);

        return CircleIterator{
            .map = map,
            .cx = cx,
            .cy = cy,
            .radius = radius,
            .x_min = x_min,
            .x_max = x_max,
            .y_min = y_min,
            .y_max = y_max,
            .x = x_min,
            .y = y_min,
        };
    }

    pub fn next(self: *CircleIterator) ?Point {
        while (self.y <= self.y_max) {
            while (self.x <= self.x_max) {
                const point = Point{ .x = self.x, .y = self.y };
                self.x += 1;

                if (geo.get_distance(self.cx, self.cy, point.x, point.y) <= self.radius) return point;
            }

            self.x = self.x_min;
            self.y += 1;
        }

        return null;
    }
};
