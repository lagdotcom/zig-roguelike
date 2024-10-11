const colours = @import("colours.zig");
const Point = @import("common.zig").Point;

pub const Glyph = struct { ch: u8, colour: colours.RGB8 };
pub const Named = struct { name: []const u8 };
pub const Position = Point;

pub const BlocksMovement = struct {};
pub const IsEnemy = struct {};
pub const IsPlayer = struct {};
