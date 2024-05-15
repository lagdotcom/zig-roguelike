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

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

pub fn main() !void {
    var term = try Terminal.init(std.io.getStdOut(), "Ziglike");
    defer term.deinit() catch {};

    const events = try EventManager.init(allocator, 100, std.io.getStdIn());
    defer events.deinit();

    var reg = Registry.init(allocator);

    var engine = Engine.init(events, &reg, term);

    const player = reg.create();
    reg.add(player, Position{
        .x = @divTrunc(term.width, 2),
        .y = @divTrunc(term.height, 2),
    });
    reg.add(player, Glyph{ .ch = '@', .colour = colours.White });
    engine.setPlayer(player);

    const npc = reg.create();
    reg.add(npc, Position{
        .x = @divTrunc(term.width, 2) - 5,
        .y = @divTrunc(term.height, 2),
    });
    reg.add(npc, Glyph{ .ch = '@', .colour = colours.Yellow });

    try engine.run();
}
