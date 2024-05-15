const colours = @import("colours.zig");

pub const Glyph = struct { ch: u8, colour: colours.RGB8 };
pub const Position = struct { x: i16, y: i16 };

pub const IsPlayer = struct {};
