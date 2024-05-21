// https://www.redblobgames.com/grids/line-drawing/

const std = @import("std");

const Point = @import("../common.zig").Point;
const PointF = @import("../common.zig").PointF;

/// Trace a line from one point to another. If callback returns false, tracing stops.
pub fn trace(p0: Point, p1: Point, callback: fn (p: Point) bool) void {
    const distance: f16 = @floatFromInt(diagonal_distance(p0, p1));

    var step: f16 = 0;
    while (step <= distance) : (step += 1) {
        const t = if (distance == 0) 0.0 else step / distance;
        const point = round_point(lerp_point(p0, p1, t));
        if (!callback(point)) return;
    }
}

fn diagonal_distance(p0: Point, p1: Point) i16 {
    const dx = p1.x - p0.x;
    const dy = p1.y - p0.y;

    return @intCast(@max(@abs(dx), @abs(dy)));
}

fn round_point(p: PointF) Point {
    return Point{
        .x = @intFromFloat(@round(p.x)),
        .y = @intFromFloat(@round(p.y)),
    };
}

fn lerp_point(p0: Point, p1: Point, t: f16) PointF {
    return PointF{
        .x = lerp(@floatFromInt(p0.x), @floatFromInt(p1.x), t),
        .y = lerp(@floatFromInt(p0.y), @floatFromInt(p1.y), t),
    };
}

fn lerp(start: f16, end: f16, t: f16) f16 {
    return start * (1.0 - t) + t * end;
}
