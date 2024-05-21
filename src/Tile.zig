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
    light: TileGraphics,
};

pub const shroud: TileGraphics = .{ .ch = ' ', .fg = colours.White, .bg = colours.Black };

pub const floor: Tile = .{
    .walkable = true,
    .transparent = true,
    .dark = .{ .ch = ' ', .fg = colours.White, .bg = colours.LightBlue },
    .light = .{ .ch = ' ', .fg = colours.White, .bg = colours.LightYellow },
};
pub const wall: Tile = .{
    .walkable = false,
    .transparent = false,
    .dark = .{ .ch = ' ', .fg = colours.White, .bg = colours.DarkBlue },
    .light = .{ .ch = ' ', .fg = colours.White, .bg = colours.DarkYellow },
};
