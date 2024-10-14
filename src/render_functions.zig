const co = @import("colours.zig");
const Terminal = @import("Terminal.zig").Terminal;

pub fn render_bar(terminal: *Terminal, current: i16, maximum: i16, total_width: usize) !void {
    const bar_width = if (current >= 0) @divTrunc(@as(usize, @intCast(current)) * total_width, @as(usize, @intCast(maximum))) else 0;

    try terminal.setBackgroundColour(co.BarEmpty);
    try terminal.drawRect(0, 45, total_width, 1, ' ');
    if (bar_width > 0) {
        try terminal.setBackgroundColour(co.BarFilled);
        try terminal.drawRect(0, 45, bar_width, 1, ' ');
    }

    try terminal.resetColour();
    try terminal.setForegroundColour(co.BarText);
    try terminal.printAt(1, 45, "HP: {}/{}", .{ current, maximum });
}
