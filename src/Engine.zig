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

const ai = @import("ai.zig");

const combat = @import("combat.zig");

pub const Engine = struct {
    allocator: Allocator,
    blockers: entt.MultiView(2, 0),
    drawables: entt.MultiView(2, 0),
    enemies: entt.MultiView(2, 0),
    event_manager: EventManager,
    map: GameMap,
    player: Entity,
    registry: *Registry,
    running: bool,
    terminal: Terminal,

    pub fn init(allocator: Allocator, event_manager: EventManager, map: GameMap, registry: *Registry, terminal: Terminal) Engine {
        return Engine{
            .allocator = allocator,
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

        inline for (@typeInfo(c.RenderOrder).Enum.fields) |ro| {
            var iter = self.drawables.entityIterator();
            while (iter.next()) |entity| {
                const glyph = self.drawables.getConst(c.Glyph, entity);
                if (glyph.order != @as(c.RenderOrder, @enumFromInt(ro.value))) continue;

                const pos = self.drawables.getConst(c.Position, entity);

                if (self.map.isVisible(pos.x, pos.y) and self.terminal.contains(pos.x, pos.y)) {
                    try self.terminal.printAt(pos.x, pos.y, "{c}", .{glyph.ch});
                    try self.terminal.setChar(pos.x, pos.y, glyph.colour, t.floor.light.bg, glyph.ch);
                }
            }
        }

        const fighter = self.registry.getConst(c.Fighter, self.player);
        try self.terminal.setForegroundColour(colours.White);
        try self.terminal.setBackgroundColour(colours.Black);
        try self.terminal.printAt(1, self.terminal.height - 1, "HP: {}/{}    ", .{ fighter.hp, fighter.max_hp });

        try self.terminal.present();
    }

    fn handle_events(self: *Engine) !void {
        for (self.event_manager.wait()) |event| {
            switch (event) {
                .key => |key| {
                    const maybe_cmd = input_handlers.process(key);
                    if (maybe_cmd) |cmd|
                        try self.perform_action(cmd);
                },

                .size => |size| {
                    try self.terminal.resize(size.dwSize.X, size.dwSize.Y);
                },

                else => {},
            }
        }
    }

    fn handle_enemy_turns(self: *Engine) !void {
        var iter = self.enemies.entityIterator();
        while (iter.next()) |entity| {
            if (self.registry.has(c.BaseAI, entity)) try ai.base_ai(self, entity);
        }
    }

    fn perform_action(self: *Engine, cmd: Action) !void {
        var spend_turn = false;

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
                    spend_turn = true;

                    const maybe_blocker = self.get_blocker_at_location(dest_x, dest_y);
                    if (maybe_blocker) |blocker| {
                        try combat.attack(self, self.player, blocker);
                    } else {
                        position.x = dest_x;
                        position.y = dest_y;
                    }
                }
            },
            .wait => {
                spend_turn = true;
            },
        }

        if (spend_turn) try self.handle_enemy_turns();
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

    pub fn get_blocker_at_location(self: *Engine, x: GameMap.Coord, y: GameMap.Coord) ?Entity {
        var iter = self.blockers.entityIterator();
        while (iter.next()) |entity| {
            const pos = self.drawables.getConst(c.Position, entity);
            if (pos.x == x and pos.y == y) return entity;
        }

        return null;
    }
};
