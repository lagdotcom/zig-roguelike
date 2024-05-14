const std = @import("std");
const ecs = @import("entt");

const console = @import("console.zig");
const input_handlers = @import("input_handlers.zig");
const Terminal = @import("Terminal.zig");
const components = @import("components.zig");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

pub fn main() !void {
    var reg = ecs.Registry.init(allocator);

    const in = std.io.getStdIn();
    const oldMode = console.setMode(in, console.ConsoleMode.ENABLE_WINDOW_INPUT);

    const out = std.io.getStdOut();
    if (!out.supportsAnsiEscapeCodes()) return error.ConsoleDoesNotSupportAnsi;

    const screen = console.getSize(out);

    const player = reg.create();
    reg.add(player, components.Position{
        .x = @divTrunc(screen.width, 2),
        .y = @divTrunc(screen.height, 2),
    });
    reg.add(player, components.Glyph{ .ch = "@" });

    var view = reg.view(.{ components.Glyph, components.Position }, .{});

    var term = Terminal.init(
        std.io.bufferedWriter(out.writer()),
        screen.width,
        screen.height,
        allocator,
    );
    try term.setWindowTitle("Ziglike");
    try term.clear();
    try term.at(0, 0);
    try term.setCursorVisible(false);

    const raw_events = try allocator.alloc(console.INPUT_RECORD_W, 100);
    defer allocator.free(raw_events);
    const events = try allocator.alloc(console.ConsoleInputEvent, 100);
    defer allocator.free(events);

    var redraw = true;
    var game_running = true;
    while (game_running) {
        if (redraw) {
            var iter = view.entityIterator();
            while (iter.next()) |entity| {
                const pos = view.getConst(components.Position, entity);
                const glyph = view.getConst(components.Glyph, entity);
                try term.printAt(pos.x, pos.y, glyph.ch);
            }

            try term.printAt(0, 0, "Press ESCAPE to quit");
            try term.present();
            try term.clear();
            redraw = false;
        }

        for (console.getEvents(in, raw_events, events)) |event| {
            switch (event) {
                .key => |key| {
                    const maybe_cmd = input_handlers.process(key);
                    if (maybe_cmd) |cmd| switch (cmd) {
                        .escape => {
                            game_running = false;
                        },
                        .movement => |move| {
                            var position = reg.get(components.Position, player);
                            position.x += move.dx;
                            position.y += move.dy;
                            redraw = true;
                        },
                    };
                },

                else => {},
            }
        }

        std.time.sleep(50_000);
    }

    try term.clear();
    try term.at(0, 0);
    try term.softReset();
    try term.present();

    _ = console.setMode(in, oldMode);
}
