pub const RGB8 = struct { r: u8, g: u8, b: u8 };

pub const white = RGB8{ .r = 255, .g = 255, .b = 255 };
pub const yellow = RGB8{ .r = 255, .g = 255, .b = 0 };
pub const black = RGB8{ .r = 0, .g = 0, .b = 0 };
pub const cyan = RGB8{ .r = 0, .g = 255, .b = 255 };
pub const red = RGB8{ .r = 255, .g = 0, .b = 0 };
pub const orange = RGB8{ .r = 255, .g = 127, .b = 0 };
pub const pink = RGB8{ .r = 255, .g = 192, .b = 255 };

pub const light_blue = RGB8{ .r = 50, .g = 50, .b = 100 };
pub const dark_blue = RGB8{ .r = 0, .g = 0, .b = 100 };
pub const light_yellow = RGB8{ .r = 200, .g = 180, .b = 50 };
pub const dark_yellow = RGB8{ .r = 130, .g = 110, .b = 50 };

pub const player_attack = RGB8{ .r = 0xe0, .g = 0xe0, .b = 0xe0 };
pub const enemy_attack = RGB8{ .r = 0xff, .g = 0xc0, .b = 0xc0 };

pub const player_die = RGB8{ .r = 0xff, .g = 0x30, .b = 0x30 };
pub const enemy_die = RGB8{ .r = 0xff, .g = 0xa0, .b = 0x30 };

pub const invalid = RGB8{ .r = 0xff, .g = 0xff, .b = 0 };
pub const impossible = RGB8{ .r = 0x80, .g = 0x80, .b = 0x80 };
pub const error_text = RGB8{ .r = 0xff, .g = 0x40, .b = 0x40 };

pub const welcome_text = RGB8{ .r = 0x20, .g = 0xa0, .b = 0xff };
pub const health_recovered = RGB8{ .r = 0, .g = 0xff, .b = 0 };

pub const bar_text = white;
pub const bar_filled = RGB8{ .r = 0, .g = 0x60, .b = 0 };
pub const bar_empty = RGB8{ .r = 0x40, .g = 0x10, .b = 0x10 };

pub const targeting_highlight = RGB8{ .r = 50, .g = 100, .b = 150 };
pub const targeting_cursor = yellow;
pub const targeting_cursor_invalid = red;
