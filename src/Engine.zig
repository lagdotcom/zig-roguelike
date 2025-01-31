const std = @import("std");
const Allocator = std.mem.Allocator;
const entt = @import("entt");
const Entity = entt.Entity;
const Registry = entt.Registry;
const Set = @import("ziglangSet").Set;

const Action = @import("actions.zig").Action;
const ai = @import("ai.zig");
const arch = @import("arch.zig");
const CircleIterator = @import("CircleIterator.zig").CircleIterator;
const c = @import("components.zig");
const col = @import("colours.zig");
const combat = @import("combat.zig");
const EventManager = @import("console.zig").EventManager;
const fov = @import("algo/fov.zig");
const GameMap = @import("GameMap.zig").GameMap;
const geo = @import("algo/geometry.zig");
const input_handlers = @import("input_handlers.zig");
const MessageLog = @import("MessageLog.zig").MessageLog;
const Point = @import("common.zig").Point;
const rf = @import("render_functions.zig");
const t = @import("Tile.zig");
const Terminal = @import("Terminal.zig").Terminal;
const windows = @import("arch/windows.zig");

const GameState = union(enum) {
    in_dungeon: void,
    use_item: void,
    drop_item: void,
    show_targeting: struct { range: i16, item: Entity },
};

pub const Engine = struct {
    allocator: Allocator,
    blocker_view: entt.MultiView(2, 0),
    carried_view: entt.MultiView(2, 0),
    drawable_view: entt.MultiView(2, 0),
    enemy_view: entt.MultiView(2, 0),
    event_manager: EventManager,
    fighter_view: entt.MultiView(2, 0),
    floor_items_view: entt.MultiView(2, 0),
    map: GameMap,
    message_log: MessageLog,
    mouse_location: Point,
    named_view: entt.MultiView(2, 0),
    player: Entity,
    registry: *Registry,
    running: bool,
    state: GameState,
    terminal: Terminal,

    pub fn init(allocator: Allocator, event_manager: EventManager, map: GameMap, registry: *Registry, terminal: Terminal) !Engine {
        return Engine{
            .allocator = allocator,
            .blocker_view = registry.view(.{ c.BlocksMovement, c.Position }, .{}),
            .carried_view = registry.view(.{ c.Carried, c.Item }, .{}),
            .drawable_view = registry.view(.{ c.Glyph, c.Position }, .{}),
            .enemy_view = registry.view(.{ c.IsEnemy, c.Named }, .{}),
            .event_manager = event_manager,
            .fighter_view = registry.view(.{ c.Fighter, c.Position }, .{}),
            .floor_items_view = registry.view(.{ c.Item, c.Position }, .{}),
            .map = map,
            .message_log = try MessageLog.init(allocator),
            .mouse_location = .{ .x = 0, .y = 0 },
            .named_view = registry.view(.{ c.Named, c.Position }, .{}),
            .player = 0,
            .registry = registry,
            .running = false,
            .state = .in_dungeon,
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

    pub fn set_player(self: *Engine, e: Entity) void {
        self.registry.add(e, c.IsPlayer{});
        self.player = e;
    }

    pub fn render(self: *Engine) !void {
        var highlights = try self.get_target_highlight_set();
        defer highlights.deinit();
        try self.map.draw(&self.terminal, highlights, col.targeting_highlight);

        try self.terminal.set_foreground_colour(col.white);

        if (arch.run_forever) {
            try self.terminal.print_at(self.terminal.width - 20, self.terminal.height - 1, "Press ESCAPE to quit", .{});
        }

        try self.render_drawable_entities(highlights);

        try self.message_log.render(&self.terminal, 21, 45, @intCast(self.terminal.width - 21), @intCast(self.terminal.height - 45));

        const fighter = self.registry.getConst(c.Fighter, self.player);
        try rf.render_bar(&self.terminal, fighter.hp, fighter.max_hp, 20);

        try self.terminal.draw_rectangle(21, 44, @intCast(self.terminal.width - 21), 1, ' ');
        try self.render_under_cursor();

        switch (self.state) {
            .use_item, .drop_item => try self.render_inventory(),
            .show_targeting => try self.render_targeting(highlights),
            else => {},
        }

        try self.terminal.present();
    }

    fn render_drawable_entities(self: *Engine, highlights: Set(GameMap.Index)) !void {
        inline for (@typeInfo(c.RenderOrder).Enum.fields) |ro| {
            var iter = self.drawable_view.entityIterator();
            while (iter.next()) |entity| {
                const glyph = self.drawable_view.getConst(c.Glyph, entity);
                if (glyph.order != @as(c.RenderOrder, @enumFromInt(ro.value))) continue;

                const pos = self.drawable_view.getConst(c.Position, entity);

                if (self.map.is_visible(pos.x, pos.y) and self.terminal.contains(pos.x, pos.y)) {
                    const index = self.map.get_index(pos.x, pos.y);
                    const bg = if (highlights.contains(index)) col.targeting_highlight else t.floor.light.bg;

                    try self.terminal.print_at(pos.x, pos.y, "{c}", .{glyph.ch});
                    try self.terminal.set_char(pos.x, pos.y, glyph.colour, bg, glyph.ch);
                }
            }
        }
    }

    fn render_inventory(self: *Engine) !void {
        const inventory = try self.get_carried_items(self.player);
        defer self.allocator.free(inventory);

        const count: i16 = @intCast(inventory.len);
        var y: i16 = @intCast(25 - @divFloor(count, 2));

        try rf.render_box(&self.terminal, 15, @intCast(y - 2), 31, @intCast(count + 4), col.white, col.black);

        try self.terminal.set_foreground_colour(col.yellow);
        try self.terminal.print_at(18, @intCast(y - 2), "Inventory", .{});
        try self.terminal.print_at(18, @intCast(y + count + 1), "ESCAPE to cancel", .{});

        var i: u8 = 0;
        for (inventory) |item| {
            try self.terminal.set_char(17, y, col.white, col.black, '(');
            try self.terminal.set_char(18, y, col.yellow, col.black, @intCast(i + 97));
            try self.terminal.set_char(19, y, col.white, col.black, ')');

            try self.terminal.print_at(21, y, "{s}", .{self.get_name(item)});
            y += 1;
            i += 1;
        }
    }

    fn render_under_cursor(self: *Engine) !void {
        if (try self.get_names_at_location(self.mouse_location.x, self.mouse_location.y)) |names| {
            try self.terminal.print_at(21, 44, "{s}", .{names});
            self.allocator.free(names);
        }
    }

    fn get_target_highlight_set(self: *Engine) !Set(GameMap.Index) {
        var set = Set(GameMap.Index).init(self.allocator);

        switch (self.state) {
            .show_targeting => |targeting| {
                const position = self.registry.getConst(c.Position, self.player);
                var iter = CircleIterator.init(self.map, position.x, position.y, targeting.range);
                while (iter.next()) |point| {
                    if (!self.map.is_visible(point.x, point.y)) continue;
                    const index = self.map.get_index(point.x, point.y);
                    _ = try set.add(index);
                }
            },
            else => {},
        }

        return set;
    }

    fn render_targeting(self: *Engine, highlights: Set(GameMap.Index)) !void {
        try self.terminal.set_foreground_colour(col.yellow);
        try self.terminal.set_background_colour(col.black);
        try self.terminal.print_at(5, 0, "Select Target:", .{});

        const index = self.map.get_index(self.mouse_location.x, self.mouse_location.y);

        try self.terminal.set_char(
            self.mouse_location.x,
            self.mouse_location.y,
            if (highlights.contains(index)) col.targeting_cursor else col.targeting_cursor_invalid,
            col.targeting_highlight,
            'X',
        );
    }

    fn handle_events(self: *Engine) !void {
        for (self.event_manager.wait()) |event| {
            switch (event) {
                .key => |e| {
                    try self.handle_key(e);
                },

                .size => |e| {
                    try self.terminal.resize(e.dwSize.X, e.dwSize.Y);
                },

                .mouse => |e| {
                    const pos = e.dwMousePosition;
                    if (self.map.contains(pos.X, pos.Y)) self.mouse_location = .{ .x = pos.X, .y = pos.Y };

                    try self.terminal.print_at(21, 43, "e{d} b{d}: {d},{d}", .{ e.dwEventFlags, e.dwButtonState, e.dwMousePosition.X, e.dwMousePosition.Y });
                },

                else => {},
            }
        }
    }

    fn handle_key(self: *Engine, e: windows.KEY_EVENT_RECORD_W) !void {
        if (switch (self.state) {
            .use_item => input_handlers.use_from_inventory(e),
            .drop_item => input_handlers.drop_from_inventory(e),
            .show_targeting => input_handlers.show_targeting(e),
            else => input_handlers.in_dungeon(e),
        }) |cmd|
            try self.perform_action(cmd);
    }

    pub fn handle_enemy_turns(self: *Engine) !void {
        var iter = self.enemy_view.entityIterator();
        while (iter.next()) |entity| {
            if (self.registry.has(c.BaseAI, entity)) try ai.base_ai(self, entity);
        }
    }

    pub fn perform_action(self: *Engine, cmd: Action) !void {
        const position = self.registry.get(c.Position, self.player);
        var spend_turn = false;

        // TODO Confused on player

        switch (cmd) {
            .escape => {
                self.running = false;
                return;
            },

            .movement => |move| {
                const dest_x = position.x + move.dx;
                const dest_y = position.y + move.dy;

                if (self.map.contains(dest_x, dest_y) and self.map.get_tile(dest_x, dest_y).walkable) {
                    spend_turn = true;

                    if (self.get_fighter_at_location(dest_x, dest_y)) |fighter| {
                        try combat.attack(self, self.player, fighter);
                    } else {
                        position.x = dest_x;
                        position.y = dest_y;
                    }
                }
            },

            .pickup => {
                const backpack = self.registry.getConst(c.Inventory, self.player);

                const carried = try self.get_carried_items(self.player);
                defer self.allocator.free(carried);
                var carry_count = carried.len;

                const items = try self.get_items_at_location(position.x, position.y);
                defer self.allocator.free(items);
                for (items) |item| {
                    if (backpack.capacity <= carry_count) {
                        try self.impossible("Your inventory is full.", .{});
                        break;
                    }

                    self.registry.remove(c.Position, item);
                    self.registry.add(item, c.Carried{ .owner = self.player });
                    try self.add_to_log("You pick up the {s}.", .{self.get_name(item)}, col.white, true);
                    carry_count += 1;
                    spend_turn = true;
                }

                if (items.len == 0)
                    try self.impossible("There's nothing here to pick up.", .{});
            },

            .show_use_inventory => {
                const carried = try self.get_carried_items(self.player);
                defer self.allocator.free(carried);

                if (carried.len == 0) {
                    try self.impossible("You're not carrying anything.", .{});
                } else {
                    self.state = .use_item;
                }
            },

            .use_from_inventory => |u| {
                const carried = try self.get_carried_items(self.player);
                defer self.allocator.free(carried);

                if (u.index < carried.len) {
                    const item = carried[u.index];
                    spend_turn = try self.use_item(item, null);
                    if (spend_turn) self.state = .in_dungeon;
                }
            },

            .show_drop_inventory => {
                const carried = try self.get_carried_items(self.player);
                defer self.allocator.free(carried);

                if (carried.len == 0) {
                    try self.impossible("You're not carrying anything.", .{});
                } else {
                    self.state = .drop_item;
                }
            },

            .drop_from_inventory => |u| {
                const carried = try self.get_carried_items(self.player);
                defer self.allocator.free(carried);

                if (u.index < carried.len) {
                    const item = carried[u.index];

                    self.registry.remove(c.Carried, item);
                    self.registry.add(item, c.Position{ .x = position.x, .y = position.y });
                    try self.add_to_log("You drop the {s}.", .{self.get_name(item)}, col.white, true);

                    spend_turn = true;
                    self.state = .in_dungeon;
                }
            },

            .cursor_movement => |move| {
                self.mouse_location = .{
                    .x = self.map.clamp_x(self.mouse_location.x + move.dx),
                    .y = self.map.clamp_y(self.mouse_location.y + move.dy),
                };
            },

            .cancel_menu => {
                self.state = .in_dungeon;
            },

            .confirm_target => {
                spend_turn = try self.use_item(self.state.show_targeting.item, self.mouse_location);
                if (spend_turn) self.state = .in_dungeon;
            },

            .wait => {
                spend_turn = true;
            },
        }

        if (spend_turn) try self.handle_enemy_turns();
    }

    fn use_item(self: *Engine, item: Entity, maybe_aim: ?Point) !bool {
        var spend_turn = false;
        var targets = Set(Entity).init(self.allocator);
        defer targets.deinit();

        const maybe_ranged = self.registry.tryGetConst(c.RangedEffect, item);
        const maybe_aoe = self.registry.tryGetConst(c.AreaOfEffect, item);

        if (maybe_aim) |aim| {
            if (maybe_ranged != null) {
                if (maybe_aoe) |aoe| {
                    var iter = CircleIterator.init(self.map, aim.x, aim.y, aoe.radius);
                    while (iter.next()) |point| {
                        if (self.get_fighter_at_location(point.x, point.y)) |victim| {
                            _ = try targets.add(victim);
                        }
                    }
                } else if (self.get_fighter_at_location(aim.x, aim.y)) |victim| {
                    _ = try targets.add(victim);
                }
            }
        } else {
            if (maybe_ranged) |ranged| {
                const position = self.registry.getConst(c.Position, self.player);
                self.state = .{ .show_targeting = .{ .range = ranged.range, .item = item } };
                self.mouse_location = .{ .x = position.x, .y = position.y };
                return false;
            }

            _ = try targets.add(self.player);
        }

        if (targets.isEmpty()) {
            try self.impossible("No target.", .{});
            return false;
        }

        var tried_to_heal = false;
        var successful_heals: i16 = 0;

        var tried_to_damage = false;
        var successful_inflicts: i16 = 0;

        var iter = targets.iterator();
        while (iter.next()) |p_target| {
            const target = p_target.*;
            if (self.registry.tryGetConst(c.HealingItem, item)) |healing| {
                tried_to_heal = true;
                if (self.registry.tryGet(c.Fighter, target)) |fighter| {
                    const final_hp = @min(fighter.max_hp, fighter.hp + healing.amount);
                    const heal_amount = final_hp - fighter.hp;

                    if (heal_amount > 0) {
                        spend_turn = true;
                        successful_heals += 1;
                        fighter.hp = final_hp;
                        try self.add_to_log("You use the {s}, healing {d} hp.", .{ self.get_name(item), heal_amount }, col.health_recovered, true);
                    }
                }
            }

            if (self.registry.tryGetConst(c.DamagingItem, item)) |inflict| {
                tried_to_damage = true;
                if (self.registry.tryGet(c.Fighter, target)) |fighter| {
                    const final_hp = fighter.max_hp - inflict.amount;

                    spend_turn = true;
                    successful_inflicts += 1;
                    fighter.hp = final_hp;
                    try self.add_to_log("You use {s} on {s}, inflicting {d} hp.", .{ self.get_name(item), self.get_name(target), inflict.amount }, col.player_attack, true);

                    if (final_hp <= 0) try combat.kill(self, target);
                }
            }

            if (self.registry.tryGetConst(c.ConfusionEffect, item)) |effect| {
                spend_turn = true;
                self.registry.add(target, c.Confused{ .duration = effect.duration });
                try self.add_to_log("You use {s} on {s}, confusing them.", .{ self.get_name(item), self.get_name(target) }, col.white, true);
            }
        }

        if (!spend_turn) {
            if (tried_to_heal) {
                if (targets.contains(self.player)) {
                    try self.impossible("You don't need healing.", .{});
                } else {
                    try self.impossible("Nobody needs healing.", .{});
                }
            }
        } else {
            if (self.registry.has(c.Consumable, item)) self.registry.destroy(item);
        }

        return spend_turn;
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
        var iter = self.blocker_view.entityIterator();
        while (iter.next()) |entity| {
            const pos = self.registry.getConst(c.Position, entity);
            if (pos.x == x and pos.y == y) return entity;
        }

        return null;
    }

    pub fn get_fighter_at_location(self: *Engine, x: GameMap.Coord, y: GameMap.Coord) ?Entity {
        var iter = self.fighter_view.entityIterator();
        while (iter.next()) |entity| {
            const pos = self.registry.getConst(c.Position, entity);
            if (pos.x == x and pos.y == y) return entity;
        }

        return null;
    }

    pub fn get_items_at_location(self: *Engine, x: GameMap.Coord, y: GameMap.Coord) ![]Entity {
        var items = std.ArrayList(Entity).init(self.allocator);
        var iter = self.floor_items_view.entityIterator();
        while (iter.next()) |entity| {
            const position = self.registry.getConst(c.Position, entity);
            if (position.x == x and position.y == y) try items.append(entity);
        }

        return items.toOwnedSlice();
    }

    pub fn get_carried_items(self: *Engine, owner: Entity) ![]Entity {
        var items = std.ArrayList(Entity).init(self.allocator);
        var iter = self.carried_view.entityIterator();
        while (iter.next()) |entity| {
            if (self.registry.getConst(c.Carried, entity).owner == owner) try items.append(entity);
        }

        return items.toOwnedSlice();
    }

    pub fn add_to_log(self: *Engine, comptime fmt: []const u8, args: anytype, fg: col.RGB8, stack: bool) !void {
        const text = try std.fmt.allocPrint(self.allocator, fmt, args);
        try self.message_log.add(text, fg, stack);
    }

    pub fn impossible(self: *Engine, comptime fmt: []const u8, args: anytype) !void {
        return self.add_to_log(fmt, args, col.impossible, true);
    }

    pub fn get_name(self: *Engine, entity: Entity) []const u8 {
        return if (self.registry.tryGetConst(c.Named, entity)) |named| named.name else if (self.registry.has(c.Item, entity)) "something" else "someone";
    }

    pub fn get_names_at_location(self: *Engine, x: GameMap.Coord, y: GameMap.Coord) !?[]const u8 {
        if (!self.map.contains(x, y) or !self.map.is_visible(x, y)) return null;

        var names = std.ArrayList([]const u8).init(self.allocator);
        defer names.deinit();

        var iter = self.named_view.entityIterator();
        while (iter.next()) |entity| {
            const pos = self.registry.getConst(c.Position, entity);
            if (pos.x == x and pos.y == y) try names.append(self.get_name(entity));
        }

        return if (names.items.len > 0) try std.mem.join(self.allocator, ", ", names.items) else null;
    }
};
