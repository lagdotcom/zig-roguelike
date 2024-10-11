const std = @import("std");
const Allocator = std.mem.Allocator;

const entt = @import("entt");
const Entity = entt.Entity;
const Registry = entt.Registry;

const EventManager = @import("console.zig").EventManager;
const Terminal = @import("Terminal.zig").Terminal;

const colours = @import("colours.zig");
const input_handlers = @import("input_handlers.zig");

const c = @import("components.zig");

const GameMap = @import("GameMap.zig").GameMap;
const fov = @import("algo/fov.zig");
const t = @import("Tile.zig");

const arch = @import("arch.zig");

const Action = @import("actions.zig").Action;

pub const Engine = struct {
    blockers: entt.MultiView(2, 0),
    drawables: entt.MultiView(2, 0),
    enemies: entt.MultiView(2, 0),
    event_manager: EventManager,
    map: GameMap,
    player: Entity,
    registry: *Registry,
    running: bool,
    terminal: Terminal,

    pub fn init(event_manager: EventManager, map: GameMap, registry: *Registry, terminal: Terminal) Engine {
        return Engine{
            .blockers = registry.view(.{
                c.BlocksMovement,
                c.Position,
            }, .{}),
            .drawables = registry.view(.{ c.Glyph, c.Position }, .{}),
            .enemies = registry.view(.{ c.IsEnemy, c.Named }, .{}),
            .event_manager = event_manager,
            .map = map,
            .player = 0,
            .registry = registry,
            .running = false,
            .terminal = terminal,
        };
    }

    pub fn deinit(self: *Engine) void {
        self.registry.deinit();
        self.map.deinit();
        self.event_manager.deinit();
        self.terminal.deinit() catch {};
    }

    pub fn setPlayer(self: *Engine, e: Entity) void {
        self.registry.add(e, c.IsPlayer{});
        self.player = e;
    }

    pub fn render(self: *Engine) !void {
        try self.map.draw(&self.terminal);

        try self.terminal.setForegroundColour(colours.White);

        if (arch.runForever) {
            try self.terminal.printAt(self.terminal.width - 20, self.terminal.height - 1, "Press ESCAPE to quit", .{});
        }

        var iter = self.drawables.entityIterator();
        while (iter.next()) |entity| {
            const pos = self.drawables.getConst(c.Position, entity);
            const glyph = self.drawables.getConst(c.Glyph, entity);

            if (self.map.isVisible(pos.x, pos.y) and self.terminal.contains(pos.x, pos.y)) {
                try self.terminal.printAt(pos.x, pos.y, "{c}", .{glyph.ch});
                try self.terminal.setChar(pos.x, pos.y, glyph.colour, t.floor.light.bg, glyph.ch);
            }
        }

        try self.terminal.present();
    }

    fn handle_events(self: *Engine) !void {
        for (self.event_manager.wait()) |event| {
            switch (event) {
                .key => |key| {
                    const maybe_cmd = input_handlers.process(key);
                    if (maybe_cmd) |cmd|
                        self.perform_action(cmd);
                },

                .size => |size| {
                    try self.terminal.resize(size.dwSize.X, size.dwSize.Y);
                },

                else => {},
            }
        }
    }

    fn handle_enemy_turns(self: *Engine) void {
        var iter = self.enemies.entityIterator();
        while (iter.next()) |entity| {
            const name = self.registry.getConst(c.Named, entity);
            std.log.debug("{} wonders when they will get their turn.", .{name.name});
        }
    }

    fn perform_action(self: *Engine, cmd: Action) void {
        switch (cmd) {
            .escape => {
                self.running = false;
                return;
            },
            .movement => |move| {
                const position = self.registry.get(c.Position, self.player);

                const dest_x = position.x + move.dx;
                const dest_y = position.y + move.dy;

                if (self.map.contains(dest_x, dest_y) and self.map.getTile(dest_x, dest_y).walkable) {
                    const maybe_blocker = self.getBlockingEntityAtLocation(dest_x, dest_y);
                    if (maybe_blocker) |blocker| {
                        const named = self.registry.getConst(c.Named, blocker);
                        std.log.debug("You kick the {}!", .{named.name});
                        return;
                    }

                    position.x = dest_x;
                    position.y = dest_y;
                }
            },
        }

        self.handle_enemy_turns();
    }

    fn update_fov(self: *Engine) void {
        const position = self.registry.getConst(c.Position, self.player);
        fov.compute(self.map, position);
    }

    pub fn run(self: *Engine) !void {
        self.running = true;

        while (self.running) {
            try self.tick();
        }
    }

    pub fn tick(self: *Engine) !void {
        try self.handle_events();
        self.update_fov();
        try self.render();
    }

    pub fn getBlockingEntityAtLocation(self: *Engine, x: i16, y: i16) ?Entity {
        var iter = self.blockers.entityIterator();
        while (iter.next()) |entity| {
            const pos = self.drawables.getConst(c.Position, entity);
            if (pos.x == x and pos.y == y) return entity;
        }

        return null;
    }
};
