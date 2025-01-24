const col = @import("colours.zig");

const TileGraphics = struct {
    ch: u8,
    fg: col.RGB8,
    bg: col.RGB8,
};

pub const Tile = struct {
    walkable: bool,
    transparent: bool,
    dark: TileGraphics,
    light: TileGraphics,
};

pub const shroud: TileGraphics = .{ .ch = ' ', .fg = col.white, .bg = col.black };

pub const floor: Tile = .{
    .walkable = true,
    .transparent = true,
    .dark = .{ .ch = ' ', .fg = col.white, .bg = col.light_blue },
    .light = .{ .ch = ' ', .fg = col.white, .bg = col.light_yellow },
};
pub const wall: Tile = .{
    .walkable = false,
    .transparent = false,
    .dark = .{ .ch = ' ', .fg = col.white, .bg = col.dark_blue },
    .light = .{ .ch = ' ', .fg = col.white, .bg = col.dark_yellow },
};
