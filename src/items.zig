const entt = @import("entt");
const Entity = entt.Entity;
const Registry = entt.Registry;

const c = @import("components.zig");
const col = @import("colours.zig");
const Spawner = @import("spawn.zig").Spawner;

fn setup_health_potion(reg: *Registry, e: Entity) void {
    reg.add(e, c.Glyph{
        .ch = '!',
        .colour = .{ .r = 127, .g = 0, .b = 255 },
        .order = c.RenderOrder.Item,
    });
    reg.add(e, c.Named{ .name = "Health Potion" });
    reg.add(e, c.Consumable{});
    reg.add(e, c.HealingItem{ .amount = 4 });
}
pub const health_potion = Spawner{ .init = setup_health_potion };

fn setup_magic_missile_scroll(reg: *Registry, e: Entity) void {
    reg.add(e, c.Glyph{ .ch = ')', .colour = col.cyan, .order = c.RenderOrder.Item });
    reg.add(e, c.Named{ .name = "Magic Missile Scroll" });
    reg.add(e, c.Consumable{});
    reg.add(e, c.RangedEffect{ .range = 6 });
    reg.add(e, c.DamagingItem{ .amount = 8 });
}
pub const magic_missile_scroll = Spawner{ .init = setup_magic_missile_scroll };

fn setup_fireball_scroll(reg: *Registry, e: Entity) void {
    reg.add(e, c.Glyph{ .ch = ')', .colour = col.orange, .order = c.RenderOrder.Item });
    reg.add(e, c.Named{ .name = "Fireball Scroll" });
    reg.add(e, c.Consumable{});
    reg.add(e, c.RangedEffect{ .range = 6 });
    reg.add(e, c.DamagingItem{ .amount = 20 });
    reg.add(e, c.AreaOfEffect{ .radius = 3 });
}
pub const fireball_scroll = Spawner{ .init = setup_fireball_scroll };
