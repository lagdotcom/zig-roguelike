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

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

pub fn main() !void {
    var term = try Terminal.init(std.io.getStdOut(), "Ziglike");
    defer term.deinit() catch {};

    const events = try EventManager.init(allocator, 100, std.io.getStdIn());
    defer events.deinit();

    var reg = Registry.init(allocator);

    var map = try GameMap.init(allocator, 80, 45);
    defer map.deinit();

    const centre_x = @divTrunc(map.width, 2);
    const centre_y = @divTrunc(map.height, 2);

    var engine = Engine.init(events, map, &reg, term);

    const player = reg.create();
    reg.add(player, Position{
        .x = @intCast(centre_x),
        .y = @intCast(centre_y),
    });
    reg.add(player, Glyph{ .ch = '@', .colour = colours.White });
    engine.setPlayer(player);

    const npc = reg.create();
    reg.add(npc, Position{
        .x = @intCast(centre_x - 5),
        .y = @intCast(centre_y),
    });
    reg.add(npc, Glyph{ .ch = '@', .colour = colours.Yellow });

    try engine.run();
}
