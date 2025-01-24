const entt = @import("entt");
const Entity = entt.Entity;
const Registry = entt.Registry;

const c = @import("components.zig");
const Spawner = @import("spawn.zig").Spawner;

fn setup_orc(reg: *Registry, e: Entity) void {
    reg.add(e, c.Glyph{
        .ch = 'o',
        .colour = .{ .r = 63, .g = 127, .b = 63 },
        .order = c.RenderOrder.Actor,
    });
    reg.add(e, c.Named{ .name = "Orc" });
    reg.add(e, c.Fighter{ .hp = 10, .max_hp = 10, .defence = 0, .power = 3 });
    reg.add(e, c.BaseAI{});
}
pub const orc = Spawner{ .init = setup_orc };

fn setup_troll(reg: *Registry, e: Entity) void {
    reg.add(e, c.Glyph{
        .ch = 'T',
        .colour = .{ .r = 0, .g = 127, .b = 0 },
        .order = c.RenderOrder.Actor,
    });
    reg.add(e, c.Named{ .name = "Troll" });
    reg.add(e, c.Fighter{ .hp = 16, .max_hp = 16, .defence = 1, .power = 4 });
    reg.add(e, c.BaseAI{});
}
pub const troll = Spawner{ .init = setup_troll };
