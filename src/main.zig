const std = @import("std");
const Registry = @import("entt").Registry;

const EventManager = @import("console.zig").EventManager;

const input_handlers = @import("input_handlers.zig");
const Terminal = @import("Terminal.zig").Terminal;

const colours = @import("colours.zig");

const components = @import("components.zig");
const Glyph = components.Glyph;
const Position = components.Position;

const Engine = @import("Engine.zig").Engine;

const GameMap = @import("GameMap.zig").GameMap;
const procgen = @import("procgen.zig");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

pub fn main() !void {
    var term = try Terminal.init(std.io.getStdOut(), "Ziglike");
    defer term.deinit() catch {};

    const events = try EventManager.init(allocator, 100, std.io.getStdIn());
    defer events.deinit();

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    var map = try GameMap.init(allocator, 80, 45);
    defer map.deinit();
    var start = procgen.Point{ .x = 0, .y = 0 };
    try procgen.generate_dungeon(rand, map, 10, 6, 30, &start);

    var reg = Registry.init(allocator);
    defer reg.deinit();

    var engine = Engine.init(events, map, &reg, term);

    const player = reg.create();
    reg.add(player, Position{ .x = start.x, .y = start.y });
    reg.add(player, Glyph{ .ch = '@', .colour = colours.White });
    engine.setPlayer(player);

    try engine.run();
}
