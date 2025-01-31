const Entity = @import("entt").Entity;
const Set = @import("ziglangSet").Set;

const c = @import("components.zig");
const CircleIterator = @import("CircleIterator.zig").CircleIterator;
const col = @import("colours.zig");
const combat = @import("combat.zig");
const Engine = @import("Engine.zig").Engine;
const Point = @import("common.zig").Point;

pub const Action = union(enum) {
    escape: void,
    wait: void,
    movement: struct { dx: i8, dy: i8 },
    pickup: void,

    cancel_menu: void,
    show_use_inventory: void,
    use_from_inventory: struct { index: usize },
    show_drop_inventory: void,
    drop_from_inventory: struct { index: usize },

    cursor_movement: struct { dx: i8, dy: i8 },
    confirm_target: void,
};

pub fn perform_action(e: *Engine, cmd: Action) !void {
    const position = e.registry.get(c.Position, e.player);
    var spend_turn = false;

    // TODO Confused on player

    switch (cmd) {
        .escape => {
            e.running = false;
            return;
        },

        .movement => |move| {
            const dest_x = position.x + move.dx;
            const dest_y = position.y + move.dy;

            if (e.map.contains(dest_x, dest_y) and e.map.get_tile(dest_x, dest_y).walkable) {
                spend_turn = true;

                if (e.get_fighter_at_location(dest_x, dest_y)) |fighter| {
                    try combat.attack(e, e.player, fighter);
                } else {
                    position.x = dest_x;
                    position.y = dest_y;
                }
            }
        },

        .pickup => {
            const backpack = e.registry.getConst(c.Inventory, e.player);

            const carried = try e.get_carried_items(e.player);
            defer e.allocator.free(carried);
            var carry_count = carried.len;

            const items = try e.get_items_at_location(position.x, position.y);
            defer e.allocator.free(items);
            for (items) |item| {
                if (backpack.capacity <= carry_count) {
                    try e.impossible("Your inventory is full.", .{});
                    break;
                }

                e.registry.remove(c.Position, item);
                e.registry.add(item, c.Carried{ .owner = e.player });
                try e.add_to_log("You pick up the {s}.", .{e.get_name(item)}, col.white, true);
                carry_count += 1;
                spend_turn = true;
            }

            if (items.len == 0)
                try e.impossible("There's nothing here to pick up.", .{});
        },

        .show_use_inventory => {
            const carried = try e.get_carried_items(e.player);
            defer e.allocator.free(carried);

            if (carried.len == 0) {
                try e.impossible("You're not carrying anything.", .{});
            } else {
                e.state = .use_item;
            }
        },

        .use_from_inventory => |u| {
            const carried = try e.get_carried_items(e.player);
            defer e.allocator.free(carried);

            if (u.index < carried.len) {
                const item = carried[u.index];
                spend_turn = try use_item(e, e.player, item, null);
                if (spend_turn) e.state = .in_dungeon;
            }
        },

        .show_drop_inventory => {
            const carried = try e.get_carried_items(e.player);
            defer e.allocator.free(carried);

            if (carried.len == 0) {
                try e.impossible("You're not carrying anything.", .{});
            } else {
                e.state = .drop_item;
            }
        },

        .drop_from_inventory => |u| {
            const carried = try e.get_carried_items(e.player);
            defer e.allocator.free(carried);

            if (u.index < carried.len) {
                const item = carried[u.index];

                e.registry.remove(c.Carried, item);
                e.registry.add(item, c.Position{ .x = position.x, .y = position.y });
                try e.add_to_log("You drop the {s}.", .{e.get_name(item)}, col.white, true);

                spend_turn = true;
                e.state = .in_dungeon;
            }
        },

        .cursor_movement => |move| {
            e.mouse_location = .{
                .x = e.map.clamp_x(e.mouse_location.x + move.dx),
                .y = e.map.clamp_y(e.mouse_location.y + move.dy),
            };
        },

        .cancel_menu => {
            e.state = .in_dungeon;
        },

        .confirm_target => {
            spend_turn = try use_item(e, e.player, e.state.show_targeting.item, e.mouse_location);
            if (spend_turn) e.state = .in_dungeon;
        },

        .wait => {
            spend_turn = true;
        },
    }

    if (spend_turn) try e.handle_enemy_turns();
}

pub fn use_item(e: *Engine, user: Entity, item: Entity, maybe_aim: ?Point) !bool {
    var spend_turn = false;
    var targets = Set(Entity).init(e.allocator);
    defer targets.deinit();

    const maybe_ranged = e.registry.tryGetConst(c.RangedEffect, item);
    const maybe_aoe = e.registry.tryGetConst(c.AreaOfEffect, item);

    if (maybe_aim) |aim| {
        const aim_index = e.map.get_index(aim.x, aim.y);
        if (!e.targeting_valid.contains(aim_index)) {
            try e.impossible("Out of range.", .{});
            return false;
        }

        if (maybe_ranged != null) {
            if (maybe_aoe) |aoe| {
                var iter = CircleIterator.init(e.map, aim.x, aim.y, aoe.radius);
                while (iter.next()) |point| {
                    if (e.get_fighter_at_location(point.x, point.y)) |victim| {
                        _ = try targets.add(victim);
                    }
                }
            } else if (e.get_fighter_at_location(aim.x, aim.y)) |victim| {
                _ = try targets.add(victim);
            }
        }
    } else {
        if (maybe_ranged) |ranged| {
            const maybe_area = e.registry.tryGetConst(c.AreaOfEffect, item);
            const position = e.registry.getConst(c.Position, user);
            e.state = .{ .show_targeting = .{
                .range = ranged.range,
                .area = if (maybe_area == null) 1 else maybe_area.?.radius,
                .item = item,
            } };
            e.mouse_location = .{ .x = position.x, .y = position.y };
            return false;
        }

        _ = try targets.add(user);
    }

    if (targets.isEmpty()) {
        try e.impossible("No target.", .{});
        return false;
    }

    var tried_to_heal = false;
    var successful_heals: i16 = 0;

    var tried_to_damage = false;
    var successful_inflicts: i16 = 0;

    var iter = targets.iterator();
    while (iter.next()) |p_target| {
        const target = p_target.*;
        if (e.registry.tryGetConst(c.HealingItem, item)) |healing| {
            tried_to_heal = true;
            if (e.registry.tryGet(c.Fighter, target)) |fighter| {
                const final_hp = @min(fighter.max_hp, fighter.hp + healing.amount);
                const heal_amount = final_hp - fighter.hp;

                if (heal_amount > 0) {
                    spend_turn = true;
                    successful_heals += 1;
                    fighter.hp = final_hp;
                    try e.add_to_log("You use the {s}, healing {d} hp.", .{ e.get_name(item), heal_amount }, col.health_recovered, true);
                }
            }
        }

        if (e.registry.tryGetConst(c.DamagingItem, item)) |inflict| {
            tried_to_damage = true;
            if (e.registry.tryGet(c.Fighter, target)) |fighter| {
                const final_hp = fighter.max_hp - inflict.amount;

                spend_turn = true;
                successful_inflicts += 1;
                fighter.hp = final_hp;
                try e.add_to_log("You use {s} on {s}, inflicting {d} hp.", .{ e.get_name(item), e.get_name(target), inflict.amount }, col.player_attack, true);

                if (final_hp <= 0) try combat.kill(e, target);
            }
        }

        if (e.registry.tryGetConst(c.ConfusionEffect, item)) |effect| {
            spend_turn = true;
            e.registry.add(target, c.Confused{ .duration = effect.duration });
            try e.add_to_log("You use {s} on {s}, confusing them.", .{ e.get_name(item), e.get_name(target) }, col.white, true);
        }
    }

    if (!spend_turn) {
        if (tried_to_heal) {
            if (targets.contains(user)) {
                try e.impossible("You don't need healing.", .{});
            } else {
                try e.impossible("Nobody needs healing.", .{});
            }
        }
    } else {
        if (e.registry.has(c.Consumable, item)) e.registry.destroy(item);
    }

    return spend_turn;
}
