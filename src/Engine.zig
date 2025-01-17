const std = @import("std");
const Allocator = std.mem.Allocator;
const entt = @import("entt");
const Entity = entt.Entity;
const Registry = entt.Registry;

const Action = @import("actions.zig").Action;
const ai = @import("ai.zig");
const arch = @import("arch.zig");
const c = @import("components.zig");
const colours = @import("colours.zig");
const combat = @import("combat.zig");
const EventManager = @import("console.zig").EventManager;
const fov = @import("algo/fov.zig");
const GameMap = @import("GameMap.zig").GameMap;
const input_handlers = @import("input_handlers.zig");
const MessageLog = @import("MessageLog.zig").MessageLog;
const Point = @import("common.zig").Point;
const rf = @import("render_functions.zig");
const RGB8 = @import("colours.zig").RGB8;
const t = @import("Tile.zig");
const Terminal = @import("Terminal.zig").Terminal;

pub const Engine = struct {
    allocator: Allocator,
    blockers: entt.MultiView(2, 0),
    carried_items: entt.MultiView(2, 0),
    drawables: entt.MultiView(2, 0),
    enemies: entt.MultiView(2, 0),
    event_manager: EventManager,
    floor_items: entt.MultiView(2, 0),
    map: GameMap,
    message_log: MessageLog,
    mouse_location: Point,
    named: entt.MultiView(2, 0),
    player: Entity,
    registry: *Registry,
    running: bool,
    terminal: Terminal,

    pub fn init(allocator: Allocator, event_manager: EventManager, map: GameMap, registry: *Registry, terminal: Terminal) !Engine {
        return Engine{
            .allocator = allocator,
            .blockers = registry.view(.{ c.BlocksMovement, c.Position }, .{}),
            .carried_items = registry.view(.{ c.Carried, c.Item }, .{}),
            .drawables = registry.view(.{ c.Glyph, c.Position }, .{}),
            .enemies = registry.view(.{ c.IsEnemy, c.Named }, .{}),
            .event_manager = event_manager,
            .floor_items = registry.view(.{ c.Item, c.Position }, .{}),
            .map = map,
            .message_log = try MessageLog.init(allocator),
            .mouse_location = .{ .x = 0, .y = 0 },
            .named = registry.view(.{ c.Named, c.Position }, .{}),
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
        self.message_log.deinit();
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

        try self.message_log.render(&self.terminal, 21, 45, @intCast(self.terminal.width - 21), 5);

        const fighter = self.registry.getConst(c.Fighter, self.player);
        try rf.render_bar(&self.terminal, fighter.hp, fighter.max_hp, 20);

        try self.terminal.drawRect(21, 44, @intCast(self.terminal.width - 21), 1, ' ');
        const maybe_names = try self.get_names_at_location(self.mouse_location.x, self.mouse_location.y);
        if (maybe_names) |names| {
            try self.terminal.printAt(21, 44, "{s}", .{names});
            self.allocator.free(names);
        }

        try self.terminal.present();
    }

    fn handle_events(self: *Engine) !void {
        for (self.event_manager.wait()) |event| {
            switch (event) {
                .key => |e| {
                    const maybe_cmd = input_handlers.process(e);
                    if (maybe_cmd) |cmd|
                        try self.perform_action(cmd);
                },

                .size => |e| {
                    try self.terminal.resize(e.dwSize.X, e.dwSize.Y);
                },

                .mouse => |e| {
                    const pos = e.dwMousePosition;
                    if (self.map.contains(pos.X, pos.Y)) self.mouse_location = .{ .x = pos.X, .y = pos.Y };

                    try self.terminal.printAt(21, 43, "e{d} b{d}: {d},{d}", .{ e.dwEventFlags, e.dwButtonState, e.dwMousePosition.X, e.dwMousePosition.Y });
                },

                else => {},
            }
        }
    }

    pub fn handle_enemy_turns(self: *Engine) !void {
        var iter = self.enemies.entityIterator();
        while (iter.next()) |entity| {
            if (self.registry.has(c.BaseAI, entity)) try ai.base_ai(self, entity);
        }
    }

    pub fn perform_action(self: *Engine, cmd: Action) !void {
        const position = self.registry.get(c.Position, self.player);
        var spend_turn = false;

        switch (cmd) {
            .escape => {
                self.running = false;
                return;
            },

            .movement => |move| {
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

            .pickup => {
                const backpack = self.registry.getConst(c.Inventory, self.player);

                const carried = try self.get_carried_items(self.player);
                var carry_count = carried.len;
                self.allocator.free(carried);

                const items = try self.get_items_at_location(position.x, position.y);
                defer self.allocator.free(items);
                for (items) |item| {
                    if (backpack.capacity <= carry_count) {
                        try self.impossible("Your inventory is full.", .{});
                        break;
                    }

                    const name = self.registry.getConst(c.Named, item);
                    self.registry.remove(c.Position, item);
                    self.registry.add(item, c.Carried{ .owner = self.player });
                    try self.add_to_log("You pick up the {s}.", .{name.name}, colours.White, true);
                    carry_count += 1;
                    spend_turn = true;
                }

                if (items.len == 0)
                    try self.impossible("There's nothing here to pick up.", .{});
            },

            .use => |item| {
                // TODO
                _ = item;
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

    pub fn get_items_at_location(self: *Engine, x: GameMap.Coord, y: GameMap.Coord) !std.ArrayList(Entity).Slice {
        var items = std.ArrayList(Entity).init(self.allocator);
        var iter = self.floor_items.entityIterator();
        while (iter.next()) |entity| {
            const position = self.registry.getConst(c.Position, entity);
            if (position.x == x and position.y == y) try items.append(entity);
        }

        return items.toOwnedSlice();
    }

    pub fn get_carried_items(self: *Engine, owner: Entity) !std.ArrayList(Entity).Slice {
        var items = std.ArrayList(Entity).init(self.allocator);
        var iter = self.carried_items.entityIterator();
        while (iter.next()) |entity| {
            if (self.registry.getConst(c.Carried, entity).owner == owner) try items.append(entity);
        }

        return items.toOwnedSlice();
    }

    pub fn add_to_log(self: *Engine, comptime fmt: []const u8, args: anytype, fg: RGB8, stack: bool) !void {
        const text = try std.fmt.allocPrint(self.allocator, fmt, args);
        try self.message_log.add(text, fg, stack);
    }

    pub fn impossible(self: *Engine, comptime fmt: []const u8, args: anytype) !void {
        return self.add_to_log(fmt, args, colours.Impossible, true);
    }

    pub fn get_names_at_location(self: *Engine, x: GameMap.Coord, y: GameMap.Coord) !?[]const u8 {
        if (!self.map.contains(x, y) or !self.map.isVisible(x, y)) return null;

        var names = std.ArrayList([]const u8).init(self.allocator);
        defer names.deinit();

        var iter = self.named.entityIterator();
        while (iter.next()) |entity| {
            const pos = self.registry.getConst(c.Position, entity);
            if (pos.x == x and pos.y == y) try names.append(self.registry.getConst(c.Named, entity).name);
        }

        return if (names.items.len > 0) try std.mem.join(self.allocator, ", ", names.items) else null;
    }
};
