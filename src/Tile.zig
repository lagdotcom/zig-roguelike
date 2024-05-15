const colours = @import("colours.zig");

const TileGraphics = struct {
    ch: u8,
    fg: colours.RGB8,
    bg: colours.RGB8,
};

pub const Tile = struct {
    walkable: bool,
    transparent: bool,
    dark: TileGraphics,
};

pub const floor: Tile = .{
    .walkable = true,
    .transparent = true,
    .dark = .{ .ch = ' ', .fg = colours.White, .bg = colours.LightBlue },
};
pub const wall: Tile = .{
    .walkable = false,
    .transparent = false,
    .dark = .{ .ch = ' ', .fg = colours.White, .bg = colours.DarkBlue },
};
