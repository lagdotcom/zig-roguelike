const colours = @import("colours.zig");
const Point = @import("common.zig").Point;

pub const RenderOrder = enum(u8) {
    Corpse,
    Item,
    Actor,
};

pub const Fighter = struct { hp: i16, max_hp: i16, defense: i16, power: i16 };
pub const Glyph = struct { ch: u8, colour: colours.RGB8, order: RenderOrder };
pub const Named = struct { name: []const u8 };
pub const Position = Point;

pub const BaseAI = struct {};
pub const BlocksMovement = struct {};
pub const IsEnemy = struct {};
pub const IsPlayer = struct {};
