const Entity = @import("entt").Entity;

const col = @import("colours.zig");
const Point = @import("common.zig").Point;

pub const RenderOrder = enum(u8) {
    Corpse,
    Item,
    Actor,
};

// visuals
pub const Glyph = struct { ch: u8, colour: col.RGB8, order: RenderOrder };
pub const Named = struct { name: []const u8 };
pub const Position = Point;

// movement
pub const BlocksMovement = struct {};

// combat
pub const BaseAI = struct {};
pub const Fighter = struct { hp: i16, max_hp: i16, defence: i16, power: i16 };
pub const IsEnemy = struct {};
pub const IsPlayer = struct {};

// items
pub const AreaOfEffect = struct { radius: i16 };
pub const Carried = struct { owner: Entity };
pub const Consumable = struct {};
pub const DamagingItem = struct { amount: i16 };
pub const HealingItem = struct { amount: i16 };
pub const Inventory = struct { capacity: i16 };
pub const Item = struct {};
pub const RangedEffect = struct { range: i16 };
