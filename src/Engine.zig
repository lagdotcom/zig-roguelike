const std = @import("std");
const Allocator = std.mem.Allocator;

const entt = @import("entt");
const Entity = entt.Entity;
const Registry = entt.Registry;

const EventManager = @import("console.zig").EventManager;
const Terminal = @import("Terminal.zig").Terminal;

const colours = @import("colours.zig");
const input_handlers = @import("input_handlers.zig");

const components = @import("components.zig");
const Glyph = components.Glyph;
const IsPlayer = components.IsPlayer;
const Position = components.Position;

pub const Engine = struct {
    drawables: entt.MultiView(2, 0),
    event_manager: EventManager,
    player: Entity,
    registry: *Registry,
    running: bool,
    terminal: Terminal,

    pub fn init(event_manager: EventManager, registry: *Registry, terminal: Terminal) Engine {
        return Engine{
            .drawables = registry.view(.{ Glyph, Position }, .{}),
            .event_manager = event_manager,
            .player = 0,
            .registry = registry,
            .running = false,
            .terminal = terminal,
        };
    }

    pub fn setPlayer(self: *Engine, e: Entity) void {
        self.registry.add(e, IsPlayer{});
        self.player = e;
    }

    fn render(self: *Engine) !void {
        try self.terminal.setForegroundColour(colours.White);
        try self.terminal.printAt(0, 0, "Press ESCAPE to quit", .{});

        var iter = self.drawables.entityIterator();
        while (iter.next()) |entity| {
            const pos = self.drawables.getConst(Position, entity);
            const glyph = self.drawables.getConst(Glyph, entity);

            if (self.terminal.contains(pos.x, pos.y)) {
                try self.terminal.setForegroundColour(glyph.colour);
                try self.terminal.printAt(
                    pos.x,
                    pos.y,
                    "{c}",
                    .{glyph.ch},
                );
            }
        }

        try self.terminal.present();
        try self.terminal.clear();
    }

    fn handle_events(self: *Engine) void {
        for (self.event_manager.wait()) |event| {
            switch (event) {
                .key => |key| {
                    const maybe_cmd = input_handlers.process(key);
                    if (maybe_cmd) |cmd| switch (cmd) {
                        .escape => {
                            self.running = false;
                            break;
                        },
                        .movement => |move| {
                            var position = self.registry.get(Position, self.player);
                            position.x += move.dx;
                            position.y += move.dy;
                        },
                    };
                },

                else => {},
            }
        }
    }

    pub fn run(self: *Engine) !void {
        self.running = true;

        while (self.running) {
            try self.render();
            self.handle_events();
        }
    }
};
