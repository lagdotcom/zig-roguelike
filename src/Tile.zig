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

pub const shroud: TileGraphics = .{ .ch = ' ', .fg = colours.white, .bg = colours.black };

pub const floor: Tile = .{
    .walkable = true,
    .transparent = true,
    .dark = .{ .ch = ' ', .fg = colours.white, .bg = colours.light_blue },
    .light = .{ .ch = ' ', .fg = colours.white, .bg = colours.light_yellow },
};
pub const wall: Tile = .{
    .walkable = false,
    .transparent = false,
    .dark = .{ .ch = ' ', .fg = colours.white, .bg = colours.dark_blue },
    .light = .{ .ch = ' ', .fg = colours.white, .bg = colours.dark_yellow },
};
