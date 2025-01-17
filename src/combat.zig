const std = @import("std");
const Entity = @import("entt").Entity;

const Engine = @import("Engine.zig").Engine;
const c = @import("components.zig");
const co = @import("colours.zig");

pub fn attack(e: *Engine, attack_entity: Entity, target_entity: Entity) !void {
    const attacker = e.registry.tryGetConst(c.Fighter, attack_entity);
    if (attacker == null) return error.AttackIsNotAFighter;

    const target = e.registry.tryGet(c.Fighter, target_entity);
    if (target == null) return error.TargetIsNotAFighter;

    const attacker_name = e.get_name(attack_entity);
    const target_name = e.get_name(target_entity);

    const col = if (e.registry.has(c.IsPlayer, attack_entity)) co.PlayerAttack else co.EnemyAttack;
    const damage = attacker.?.power - target.?.defence;
    if (damage > 0) {
        try e.add_to_log("{s} attacks {s} for {d} hit points", .{ attacker_name, target_name, damage }, col, true);
        take_damage(target.?, damage);
    } else {
        try e.add_to_log("{s} attacks {s} but does no damage.", .{ attacker_name, target_name }, col, true);
    }

    if (target.?.hp <= 0) try kill(e, target_entity);
}

pub fn kill(e: *Engine, target_entity: Entity) !void {
    const target_name = e.get_name(target_entity);
    const is_dead_player = e.registry.has(c.IsPlayer, target_entity);
    const col = if (is_dead_player) co.PlayerDie else co.EnemyDie;

    const maybe_position = e.registry.tryGetConst(c.Position, target_entity);
    if (maybe_position) |position| {
        const corpse = e.registry.create();
        e.registry.add(corpse, c.Position{ .x = position.x, .y = position.y });
        e.registry.add(corpse, c.Glyph{
            .ch = '%',
            .colour = .{ .r = 191, .g = 0, .b = 0 },
            .order = c.RenderOrder.Corpse,
        });

        const name = try std.fmt.allocPrint(e.allocator, "corpse of {s}", .{target_name});

        e.registry.add(corpse, c.Named{ .name = name });
    }

    if (!is_dead_player) {
        e.registry.destroy(target_entity);
        try e.add_to_log("{s} is dead!", .{target_name}, col, true);
    } else {
        try e.add_to_log("You died. Kinda.", .{}, col, true);
    }
}

pub fn heal(fighter: *c.Fighter, amount: i16) i16 {
    if (fighter.hp >= fighter.max_hp) return 0;

    const new_hp_value = @min(fighter.hp + amount, fighter.max_hp);
    const amount_recovered = new_hp_value - fighter.hp;

    fighter.hp = new_hp_value;
    return amount_recovered;
}

pub fn take_damage(fighter: *c.Fighter, amount: i16) void {
    fighter.hp -= amount;
}
