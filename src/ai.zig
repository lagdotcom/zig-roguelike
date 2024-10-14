const Engine = @import("Engine.zig").Engine;

const entt = @import("entt");
const Entity = entt.Entity;

const GameMap = @import("GameMap.zig").GameMap;

const c = @import("components.zig");

const astar = @import("algo/astar.zig");

const combat = @import("combat.zig");

const Graph = struct {
    const Iterator = struct {
        ps: [8]GameMap.Index,
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

    pub fn iterate_neighbours(self: Graph, id: GameMap.Index) Iterator {
        const pos = self.e.map.getPoint(id);
        const x: usize = @intCast(pos.x);
        const y: usize = @intCast(pos.y);
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

    pub fn gcost(self: Graph, from_i: GameMap.Index, to_i: GameMap.Index) usize {
        const from = self.e.map.getPoint(from_i);
        const to = self.e.map.getPoint(to_i);
        const dx = if (from.x > to.x) from.x - to.x else to.x - from.x;
        const dy = if (from.y > to.y) from.y - to.y else to.y - from.y;
        return @intCast(dx + dy);
    }

    pub fn hcost(self: Graph, from: GameMap.Index, to: GameMap.Index) usize {
        return self.gcost(from, to);
    }

    inline fn isReachable(self: Graph, x: GameMap.Coord, y: GameMap.Coord) bool {
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

        const next = e.map.getPoint(path.items[1]);
        pos.x = @intCast(next.x);
        pos.y = @intCast(next.y);
    }
}
