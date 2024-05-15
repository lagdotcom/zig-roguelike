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

const GameMap = @import("GameMap.zig").GameMap;

pub const Engine = struct {
    drawables: entt.MultiView(2, 0),
    event_manager: EventManager,
    map: GameMap,
    player: Entity,
    registry: *Registry,
    running: bool,
    terminal: Terminal,

    pub fn init(event_manager: EventManager, map: GameMap, registry: *Registry, terminal: Terminal) Engine {
        return Engine{
            .drawables = registry.view(.{ Glyph, Position }, .{}),
            .event_manager = event_manager,
            .map = map,
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
        try self.map.draw(&self.terminal);

        try self.terminal.setForegroundColour(colours.White);
        try self.terminal.printAt(self.terminal.width - 20, self.terminal.height - 1, "Press ESCAPE to quit", .{});

        var iter = self.drawables.entityIterator();
        while (iter.next()) |entity| {
            const pos = self.drawables.getConst(Position, entity);
            const glyph = self.drawables.getConst(Glyph, entity);

            if (self.terminal.contains(pos.x, pos.y)) {
                try self.terminal.setForegroundColour(glyph.colour);
                try self.terminal.printAt(pos.x, pos.y, "{c}", .{glyph.ch});
            }
        }

        try self.terminal.present();
        // try self.terminal.clear();
    }

    fn handle_events(self: *Engine) !void {
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

                            const dest_x = position.x + move.dx;
                            const dest_y = position.y + move.dy;

                            if (self.map.in_bounds(dest_x, dest_y) and self.map.getTile(dest_x, dest_y).walkable) {
                                position.x = dest_x;
                                position.y = dest_y;
                            }
                        },
                    };
                },

                .size => |size| {
                    try self.terminal.resize(size.dwSize.X, size.dwSize.Y);
                },

                else => {},
            }
        }
    }

    pub fn run(self: *Engine) !void {
        self.running = true;

        while (self.running) {
            try self.render();
            try self.handle_events();
        }
    }
};
