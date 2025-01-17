pub const RGB8 = struct { r: u8, g: u8, b: u8 };

pub const White: RGB8 = .{ .r = 255, .g = 255, .b = 255 };
pub const Yellow: RGB8 = .{ .r = 255, .g = 255, .b = 0 };
pub const Black: RGB8 = .{ .r = 0, .g = 0, .b = 0 };

pub const LightBlue: RGB8 = .{ .r = 50, .g = 50, .b = 100 };
pub const DarkBlue: RGB8 = .{ .r = 0, .g = 0, .b = 100 };
pub const LightYellow: RGB8 = .{ .r = 200, .g = 180, .b = 50 };
pub const DarkYellow: RGB8 = .{ .r = 130, .g = 110, .b = 50 };

pub const PlayerAttack: RGB8 = .{ .r = 0xe0, .g = 0xe0, .b = 0xe0 };
pub const EnemyAttack: RGB8 = .{ .r = 0xff, .g = 0xc0, .b = 0xc0 };

pub const PlayerDie: RGB8 = .{ .r = 0xff, .g = 0x30, .b = 0x30 };
pub const EnemyDie: RGB8 = .{ .r = 0xff, .g = 0xa0, .b = 0x30 };

pub const Invalid: RGB8 = .{ .r = 0xff, .g = 0xff, .b = 0 };
pub const Impossible: RGB8 = .{ .r = 0x80, .g = 0x80, .b = 0x80 };
pub const Error: RGB8 = .{ .r = 0xff, .g = 0x40, .b = 0x40 };

pub const WelcomeText: RGB8 = .{ .r = 0x20, .g = 0xa0, .b = 0xff };
pub const HealthRecovered: RGB8 = .{ .r = 0, .g = 0xff, .b = 0 };

pub const BarText = White;
pub const BarFilled: RGB8 = .{ .r = 0, .g = 0x60, .b = 0 };
pub const BarEmpty: RGB8 = .{ .r = 0x40, .g = 0x10, .b = 0x10 };
