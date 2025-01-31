const std = @import("std");
const Allocator = std.mem.Allocator;
const entt = @import("entt");
const Entity = entt.Entity;
const Registry = entt.Registry;
const Set = @import("ziglangSet").Set;

const actions = @import("actions.zig");
const ai = @import("ai.zig");
const arch = @import("arch.zig");
const BGOverlay = @import("GameMap.zig").BGOverlay;
const CircleIterator = @import("CircleIterator.zig").CircleIterator;
const c = @import("components.zig");
const col = @import("colours.zig");
const combat = @import("combat.zig");
const EventManager = @import("console.zig").EventManager;
const fov = @import("algo/fov.zig");
const GameMap = @import("GameMap.zig").GameMap;
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
    show_targeting: struct { range: i16, area: i16, item: Entity },
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
    targeting_area: GameMap.IndexSet,
    targeting_valid: GameMap.IndexSet,
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
            .targeting_area = GameMap.IndexSet.init(allocator),
            .targeting_valid = GameMap.IndexSet.init(allocator),
            .terminal = terminal,
        };
    }

    pub fn deinit(self: *Engine) void {
        self.registry.deinit();
        self.map.deinit();
        self.event_manager.deinit();
        self.message_log.deinit();
        self.targeting_valid.deinit();
        self.targeting_area.deinit();
        self.terminal.deinit() catch {};
    }

    pub fn set_player(self: *Engine, e: Entity) void {
        self.registry.add(e, c.IsPlayer{});
        self.player = e;
    }

    pub fn render(self: *Engine) !void {
        try self.update_targeting_overlays();
        try self.map.draw(&self.terminal, &[_]BGOverlay{
            .{ .indices = self.targeting_area, .bg = col.targeting_aoe },
            .{ .indices = self.targeting_valid, .bg = col.targeting_highlight },
        });

        try self.terminal.set_foreground_colour(col.white);

        if (arch.run_forever) {
            try self.terminal.print_at(self.terminal.width - 20, self.terminal.height - 1, "Press ESCAPE to quit", .{});
        }

        try self.render_drawable_entities();

        try self.message_log.render(&self.terminal, 21, 45, @intCast(self.terminal.width - 21), @intCast(self.terminal.height - 45));

        const fighter = self.registry.getConst(c.Fighter, self.player);
        try rf.render_bar(&self.terminal, fighter.hp, fighter.max_hp, 20);

        try self.terminal.draw_rectangle(21, 44, @intCast(self.terminal.width - 21), 1, ' ');
        try self.render_under_cursor();

        switch (self.state) {
            .use_item, .drop_item => try self.render_inventory(),
            .show_targeting => try self.render_targeting(),
            else => {},
        }

        try self.terminal.present();
    }

    fn render_drawable_entities(self: *Engine) !void {
        inline for (@typeInfo(c.RenderOrder).Enum.fields) |ro| {
            var iter = self.drawable_view.entityIterator();
            while (iter.next()) |entity| {
                const glyph = self.drawable_view.getConst(c.Glyph, entity);
                if (glyph.order != @as(c.RenderOrder, @enumFromInt(ro.value))) continue;

                const pos = self.drawable_view.getConst(c.Position, entity);

                if (self.map.is_visible(pos.x, pos.y) and self.terminal.contains(pos.x, pos.y)) {
                    try self.terminal.print_at(pos.x, pos.y, "{c}", .{glyph.ch});
                    try self.terminal.set_char(pos.x, pos.y, glyph.colour, t.floor.light.bg, glyph.ch);
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

    fn update_targeting_overlays(self: *Engine) !void {
        self.targeting_area.clearRetainingCapacity();
        self.targeting_valid.clearRetainingCapacity();

        switch (self.state) {
            .show_targeting => |targeting| {
                const position = self.registry.getConst(c.Position, self.player);
                var valid_iter = CircleIterator.init(self.map, position.x, position.y, targeting.range);
                while (valid_iter.next()) |point| {
                    if (!self.map.is_visible(point.x, point.y)) continue;
                    const index = self.map.get_index(point.x, point.y);
                    _ = try self.targeting_valid.add(index);
                }

                if (targeting.area > 1) {
                    const target_index = self.map.get_index(self.mouse_location.x, self.mouse_location.y);
                    if (self.targeting_valid.contains(target_index)) {
                        var area_iter = CircleIterator.init(self.map, self.mouse_location.x, self.mouse_location.y, targeting.area);
                        while (area_iter.next()) |point| {
                            if (!self.map.contains(point.x, point.y)) continue;
                            const index = self.map.get_index(point.x, point.y);
                            _ = try self.targeting_area.add(index);
                        }
                    }
                }
            },
            else => {},
        }
    }

    fn render_targeting(self: *Engine) !void {
        try self.terminal.set_foreground_colour(col.yellow);
        try self.terminal.set_background_colour(col.black);
        try self.terminal.print_at(5, 0, "Select Target:", .{});

        const index = self.map.get_index(self.mouse_location.x, self.mouse_location.y);

        try self.terminal.set_char(
            self.mouse_location.x,
            self.mouse_location.y,
            if (self.targeting_valid.contains(index)) col.targeting_cursor else col.targeting_cursor_invalid,
            if (self.targeting_area.contains(index)) col.targeting_aoe else col.targeting_highlight,
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

                    if (self.state == .show_targeting) {
                        if (input_handlers.show_targeting_mouse(e)) |cmd|
                            try actions.perform_action(self, cmd);
                    }
                },

                else => {},
            }
        }
    }

    fn handle_key(self: *Engine, e: windows.KEY_EVENT_RECORD_W) !void {
        if (switch (self.state) {
            .use_item => input_handlers.use_from_inventory(e),
            .drop_item => input_handlers.drop_from_inventory(e),
            .show_targeting => input_handlers.show_targeting_key(e),
            else => input_handlers.in_dungeon(e),
        }) |cmd|
            try actions.perform_action(self, cmd);
    }

    pub fn handle_enemy_turns(self: *Engine) !void {
        var iter = self.enemy_view.entityIterator();
        while (iter.next()) |entity| {
            if (self.registry.has(c.BaseAI, entity)) try ai.base_ai(self, entity);
        }
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
