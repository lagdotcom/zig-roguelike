const std = @import("std");
const Registry = @import("entt").Registry;

const EventManager = @import("console.zig").EventManager;

const input_handlers = @import("input_handlers.zig");
const Terminal = @import("Terminal.zig").Terminal;

const components = @import("components.zig");
const Glyph = components.Glyph;
const Position = components.Position;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

pub fn main() !void {
    var term = try Terminal.init(std.io.getStdOut(), "Ziglike");
    defer term.deinit() catch {};

    const events = try EventManager.init(allocator, 100, std.io.getStdIn());
    defer events.deinit();

    var reg = Registry.init(allocator);
    const player = reg.create();
    reg.add(player, Position{
        .x = @divTrunc(term.width, 2),
        .y = @divTrunc(term.height, 2),
    });
    reg.add(player, Glyph{ .ch = '@' });

    var game_running = true;
    var visible_entities = reg.view(.{ Glyph, Position }, .{});
    while (game_running) {
        try term.printAt(0, 0, "Press ESCAPE to quit", .{});

        var iter = visible_entities.entityIterator();
        while (iter.next()) |entity| {
            const pos = visible_entities.getConst(Position, entity);
            const glyph = visible_entities.getConst(Glyph, entity);

            if (term.contains(pos.x, pos.y))
                try term.printAt(
                    pos.x,
                    pos.y,
                    "{c}",
                    .{glyph.ch},
                );
        }

        try term.present();
        try term.clear();

        for (events.wait()) |event| {
            switch (event) {
                .key => |key| {
                    const maybe_cmd = input_handlers.process(key);
                    if (maybe_cmd) |cmd| switch (cmd) {
                        .escape => {
                            game_running = false;
                        },
                        .movement => |move| {
                            var position = reg.get(Position, player);
                            position.x += move.dx;
                            position.y += move.dy;
                        },
                    };
                },

                else => {},
            }
        }
    }
}
