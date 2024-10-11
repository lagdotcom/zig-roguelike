const std = @import("std");

const Engine = @import("Engine.zig").Engine;

const entt = @import("entt");
const Entity = entt.Entity;

const c = @import("components.zig");

fn get_name(e: *Engine, entity: Entity) []const u8 {
    const named = e.registry.tryGetConst(c.Named, entity);
    return if (named == null) "someone" else named.?.name;
}

pub fn attack(e: *Engine, attack_entity: Entity, target_entity: Entity) !void {
    const attacker = e.registry.tryGetConst(c.Fighter, attack_entity);
    if (attacker == null) return error.AttackIsNotAFighter;

    var target = e.registry.tryGet(c.Fighter, target_entity);
    if (target == null) return error.TargetIsNotAFighter;

    const attacker_name = get_name(e, attack_entity);
    const target_name = get_name(e, target_entity);

    const damage = attacker.?.power - target.?.defense;
    if (damage > 0) {
        std.log.debug("{} attacks {} for {} hit points", .{ attacker_name, target_name, damage });
        target.?.hp -= damage;
    } else {
        std.log.debug("{} attacks {} but does no damage.", .{ attacker_name, target_name });
    }

    if (target.?.hp <= 0) try kill(e, target_entity);
}

pub fn kill(e: *Engine, target_entity: Entity) !void {
    const target_name = get_name(e, target_entity);

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

    if (e.player != target_entity) {
        e.registry.destroy(target_entity);
        std.log.debug("{} is dead!", .{target_name});
    } else {
        std.log.debug("You died. Kinda.", .{});
    }
}
