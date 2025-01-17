const co = @import("colours.zig");
const Terminal = @import("Terminal.zig").Terminal;

pub fn render_bar(terminal: *Terminal, current: i16, maximum: i16, total_width: usize) !void {
    const bar_width = if (current >= 0) @divTrunc(@as(usize, @intCast(current)) * total_width, @as(usize, @intCast(maximum))) else 0;

    try terminal.set_background_colour(co.bar_empty);
    try terminal.draw_rectangle(0, 45, total_width, 1, ' ');
    if (bar_width > 0) {
        try terminal.set_background_colour(co.bar_filled);
        try terminal.draw_rectangle(0, 45, bar_width, 1, ' ');
    }

    try terminal.reset_colour();
    try terminal.set_foreground_colour(co.bar_text);
    try terminal.print_at(1, 45, "HP: {}/{}", .{ current, maximum });
}

pub fn render_box(terminal: *Terminal, x: i16, y: i16, w: usize, h: usize, fg: co.RGB8, bg: co.RGB8) !void {
    try terminal.set_foreground_colour(fg);
    try terminal.set_background_colour(bg);

    for (0..h) |oy| {
        const fc: u8 = if (oy == 0) '\xda' else if (oy == h - 1) '\xc0' else '\xb3';
        const mc: u8 = if (oy == 0) '\xc4' else if (oy == h - 1) '\xc4' else ' ';
        const ec: u8 = if (oy == 0) '\xbf' else if (oy == h - 1) '\xd9' else '\xb3';

        try terminal.print_at(x, y + @as(i16, @intCast(oy)), "{c}", .{fc});
        try terminal.buffer.writer().writeByteNTimes(mc, w - 2);
        try terminal.buffer.writer().writeByte(ec);
    }
}
