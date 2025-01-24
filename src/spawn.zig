const entt = @import("entt");
const Entity = entt.Entity;
const Registry = entt.Registry;

const c = @import("components.zig");

pub const Spawner = struct { init: *const fn (reg: *Registry, e: Entity) void };

pub fn monster(reg: *Registry, x: i16, y: i16) Entity {
    const e = reg.create();
    reg.add(e, c.Position{ .x = x, .y = y });
    reg.add(e, c.BlocksMovement{});
    reg.add(e, c.IsEnemy{});
    return e;
}

pub fn item(reg: *Registry, x: i16, y: i16) Entity {
    const e = reg.create();
    reg.add(e, c.Position{ .x = x, .y = y });
    reg.add(e, c.Item{});
    return e;
}
