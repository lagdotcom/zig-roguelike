const Engine = @import("Engine.zig").Engine;

const entt = @import("entt");
const Entity = entt.Entity;

const GameMap = @import("GameMap.zig").GameMap;

const c = @import("components.zig");

const astar = @import("algo/astar.zig");

const combat = @import("combat.zig");

const Graph = struct {
    const Iterator = struct {
        ps: [8]usize,
        cur: usize,
        size: usize,

        pub fn next(self: *Iterator) ?usize {
            if (self.cur >= self.size) return null;
            const idx = self.ps[self.cur];
            self.cur += 1;
            return idx;
        }
    };

    e: *Engine,
    ignore: Entity,

    pub fn init(e: *Engine, ignore: Entity) Graph {
        return Graph{ .e = e, .ignore = ignore };
    }

    pub fn iterate_neighbours(self: Graph, id: usize) Iterator {
        const x: usize = @intCast(id % self.e.map.width);
        const y: usize = @intCast(id / self.e.map.width);
        var it = Iterator{
            .ps = undefined,
            .cur = 0,
            .size = 0,
        };
        const xs = [_]usize{ x - 1, x + 1, x, x };
        const ys = [_]usize{ y, y, y - 1, y + 1 };
        for (0..4) |i| {
            if (self.isReachable(@intCast(xs[i]), @intCast(ys[i]))) {
                const nid: usize = @intCast(ys[i] * self.e.map.width + xs[i]);
                it.ps[it.size] = nid;
                it.size += 1;
            }
        }
        return it;
    }

    pub fn gcost(self: Graph, from: usize, to: usize) usize {
        const from_x = from % self.e.map.width;
        const from_y = from / self.e.map.width;
        const to_x = to % self.e.map.width;
        const to_y = to / self.e.map.width;
        const dx = if (from_x > to_x) from_x - to_x else to_x - from_x;
        const dy = if (from_y > to_y) from_y - to_y else to_y - from_y;
        return dx + dy;
    }

    pub fn hcost(self: Graph, from: usize, to: usize) usize {
        return self.gcost(from, to);
    }

    inline fn isReachable(self: Graph, x: i16, y: i16) bool {
        const blocker = self.e.get_blocker_at_location(x, y);
        return self.e.map.contains(x, y) and self.e.map.getTile(x, y).walkable and (blocker == null or blocker == self.ignore);
    }
};

pub fn base_ai(e: *Engine, entity: Entity) !void {
    var pos = e.registry.get(c.Position, entity);
    if (!e.map.isVisible(pos.x, pos.y)) return;

    const playerPos = e.registry.getConst(c.Position, e.player);

    const distance = @abs(pos.x - playerPos.x) + @abs(pos.y - playerPos.y);
    if (distance <= 1) {
        try combat.attack(e, entity, e.player);
        return;
    }

    const to = e.map.getIndex(playerPos.x, playerPos.y);
    const graph = Graph.init(e, entity);
    const from = e.map.getIndex(pos.x, pos.y);

    if (try astar.calculate_path(e.allocator, graph, from, to)) |path| {
        defer path.deinit();

        const next = path.items[1];
        const next_x = next % e.map.width;
        const next_y = next / e.map.width;
        pos.x = @intCast(next_x);
        pos.y = @intCast(next_y);
    }
}
